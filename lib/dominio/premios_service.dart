import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../datos/base_datos.dart';

/// Período de la meta de premios (Figma «Premios · Activados · Período abierto»).
enum PeriodoPremios { diaria, semanal, mensual }

/// Rango permitido de la meta en cada período (Figma «De 30 a 100 medallas por semana»).
class RangoMeta {
  final int minimo;
  final int maximo;
  final int porDefecto;
  const RangoMeta(this.minimo, this.maximo, this.porDefecto);
}

extension PeriodoPremiosTexto on PeriodoPremios {
  /// «Diaria», «Semanal», «Mensual» (selector de período).
  String get nombre => const ['Diaria', 'Semanal', 'Mensual'][index];

  /// «diaria», «semanal», «mensual» («Meta semanal: 30 medallas»).
  String get adjetivo => nombre.toLowerCase();

  /// «por día», «por semana», «por mes».
  String get unidad => const ['por día', 'por semana', 'por mes'][index];

  /// «hoy», «esta semana», «este mes» (lo que ve el niño).
  String get cuando => const ['hoy', 'esta semana', 'este mes'][index];

  /// «Meta de hoy», «Meta de la semana», «Meta del mes».
  String get tituloMeta => const ['Meta de hoy', 'Meta de la semana', 'Meta del mes'][index];

  RangoMeta get rango => PremiosService.rangos[this]!;
}

/// Configuración de premios elegida por el responsable.
class ConfigPremios {
  final bool activados;
  final PeriodoPremios periodo;
  final int meta;
  const ConfigPremios({
    this.activados = true,
    this.periodo = PeriodoPremios.semanal,
    this.meta = 30,
  });
}

/// Medallas por período. Cada rutina terminada en un día da 1 medalla (repetirla el mismo día no da otra).
/// Se cuentan desde progreso_rutina (completada = 1) entre el inicio del período y hoy, así que no se
/// guardan aparte. El período y los rangos de la meta son los del Figma (US1402).
class PremiosService extends ChangeNotifier {
  static final PremiosService _instance = PremiosService._internal();
  factory PremiosService() => _instance;
  PremiosService._internal();

  static const Map<PeriodoPremios, RangoMeta> rangos = {
    PeriodoPremios.diaria: RangoMeta(15, 25, 20),
    PeriodoPremios.semanal: RangoMeta(30, 100, 30),
    PeriodoPremios.mensual: RangoMeta(50, 100, 60),
  };

  Future<Database> get _db => BaseDatos().db;

  static PeriodoPremios _periodoDesdeTexto(Object? t) =>
      PeriodoPremios.values.firstWhere((p) => p.name == t, orElse: () => PeriodoPremios.semanal);

  Future<ConfigPremios> config() async {
    try {
      final f = await (await _db).query('configuracion_premios', where: 'id = 1');
      if (f.isEmpty) return const ConfigPremios();
      final periodo = _periodoDesdeTexto(f.first['periodo']);
      final r = periodo.rango;
      // Una meta guardada antes de los rangos actuales se lleva al rango del período.
      final meta = ((f.first['meta_semanal'] as int?) ?? r.porDefecto).clamp(r.minimo, r.maximo);
      return ConfigPremios(activados: f.first['activado'] == 1, periodo: periodo, meta: meta);
    } catch (_) {
      return const ConfigPremios();
    }
  }

  Future<void> guardar({required bool activados, required PeriodoPremios periodo, required int meta}) async {
    final r = periodo.rango;
    try {
      await (await _db).insert(
        'configuracion_premios',
        {'id': 1, 'activado': activados ? 1 : 0, 'periodo': periodo.name, 'meta_semanal': meta.clamp(r.minimo, r.maximo)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
    notifyListeners();
  }

  /// Mensaje de error de la meta escrita, o null si es válida o está vacía
  /// (Figma «Error número muy alto / muy bajo»).
  static String? errorMeta(PeriodoPremios periodo, int? meta) {
    if (meta == null) return null;
    final r = periodo.rango;
    final rango = 'Escribe un número de ${r.minimo} a ${r.maximo}.';
    if (meta > r.maximo) return 'Máximo ${r.maximo} medallas ${periodo.unidad}. $rango';
    if (meta < r.minimo) return 'Mínimo ${r.minimo} medallas ${periodo.unidad}. $rango';
    return null;
  }

  static String _clave(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Lunes de la semana actual (las fechas de progreso_rutina son AAAA-MM-DD).
  static DateTime lunesDeEstaSemana([DateTime? hoy]) {
    final h = hoy ?? DateTime.now();
    final d = DateTime(h.year, h.month, h.day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  /// Primer día del período que contiene a [hoy]: el mismo día, el lunes o el día 1 del mes.
  static DateTime inicioDelPeriodo(PeriodoPremios periodo, [DateTime? hoy]) {
    final h = hoy ?? DateTime.now();
    switch (periodo) {
      case PeriodoPremios.diaria:
        return DateTime(h.year, h.month, h.day);
      case PeriodoPremios.semanal:
        return lunesDeEstaSemana(h);
      case PeriodoPremios.mensual:
        return DateTime(h.year, h.month, 1);
    }
  }

  /// Medallas ganadas en el período actual (rutinas completadas, una por rutina y día).
  Future<int> medallasDelPeriodo(PeriodoPremios periodo) async {
    try {
      final desde = _clave(inicioDelPeriodo(periodo));
      final hasta = _clave(DateTime.now());
      final f = await (await _db).rawQuery(
        'SELECT COUNT(*) AS n FROM progreso_rutina WHERE completada = 1 AND fecha >= ? AND fecha <= ?',
        [desde, hasta],
      );
      return (f.first['n'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
