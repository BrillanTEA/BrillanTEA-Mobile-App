import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../datos/base_datos.dart';

/// Configuración de premios elegida por el responsable.
class ConfigPremios {
  final bool activados;
  final int metaSemanal;
  const ConfigPremios({this.activados = true, this.metaSemanal = PremiosService.metaPorDefecto});
}

/// Medallas semanales. Cada rutina terminada en un día da 1 medalla (repetirla el mismo día no da otra).
/// Se cuentan de lunes a domingo desde progreso_rutina (completada = 1), así que no se guardan aparte.
/// Con 5 rutinas × 7 días el máximo es 35, por eso la meta va de 10 a 35.
class PremiosService extends ChangeNotifier {
  static final PremiosService _instance = PremiosService._internal();
  factory PremiosService() => _instance;
  PremiosService._internal();

  static const int metaMinima = 10;
  static const int metaMaxima = 35;
  static const int pasoMeta = 5;
  static const int metaPorDefecto = 20;

  Future<Database> get _db => BaseDatos().db;

  Future<ConfigPremios> config() async {
    try {
      final f = await (await _db).query('configuracion_premios', where: 'id = 1');
      if (f.isEmpty) return const ConfigPremios();
      return ConfigPremios(
        activados: f.first['activado'] == 1,
        metaSemanal: (f.first['meta_semanal'] as int?) ?? metaPorDefecto,
      );
    } catch (_) {
      return const ConfigPremios();
    }
  }

  Future<void> guardar({required bool activados, required int metaSemanal}) async {
    final meta = metaSemanal.clamp(metaMinima, metaMaxima);
    try {
      await (await _db).insert(
        'configuracion_premios',
        {'id': 1, 'activado': activados ? 1 : 0, 'meta_semanal': meta},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
    notifyListeners();
  }

  static String _clave(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Lunes de la semana actual (las fechas de progreso_rutina son AAAA-MM-DD).
  static DateTime lunesDeEstaSemana([DateTime? hoy]) {
    final h = hoy ?? DateTime.now();
    final d = DateTime(h.year, h.month, h.day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  /// Medallas ganadas esta semana (rutinas completadas, una por rutina y día).
  Future<int> medallasSemana() async {
    try {
      final desde = _clave(lunesDeEstaSemana());
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
