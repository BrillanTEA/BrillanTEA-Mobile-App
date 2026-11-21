import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../datos/base_datos.dart';

/// Modelo de progreso diario para una rutina individual
class RutinaProgresoDia {
  final int pasoActual; // 0 hasta totalPasos
  final bool completada;

  const RutinaProgresoDia({
    required this.pasoActual,
    required this.completada,
  });

  Map<String, dynamic> toJson() => {
        'pasoActual': pasoActual,
        'completada': completada,
      };

  factory RutinaProgresoDia.fromJson(Map<String, dynamic> j) => RutinaProgresoDia(
        pasoActual: j['pasoActual'] as int? ?? 0,
        completada: j['completada'] as bool? ?? false,
      );
}

/// Servicio de persistencia diaria y configuración para el Módulo de Rutinas (SQLite):
/// - progreso_rutina(rutina_id, fecha, paso_actual, completada): el progreso se guarda por fecha
///   (AAAA-MM-DD), así que cada día empieza de cero y queda el historial de días anteriores.
/// - configuracion_rutina(rutina_id, activa): rutinas activadas o desactivadas en Configuración.
class RutinasService extends ChangeNotifier {
  static final RutinasService _instance = RutinasService._internal();
  factory RutinasService() => _instance;
  RutinasService._internal();

  final BaseDatos _bd = BaseDatos();

  String _getFechaHoyClave() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<Map<int, RutinaProgresoDia>> getProgresoHoy() async {
    try {
      final db = await _bd.db;
      final filas = await db.query('progreso_rutina', where: 'fecha = ?', whereArgs: [_getFechaHoyClave()]);
      return {
        for (final f in filas)
          f['rutina_id'] as int: RutinaProgresoDia(
            pasoActual: f['paso_actual'] as int? ?? 0,
            completada: f['completada'] == 1,
          ),
      };
    } catch (_) {
      return {};
    }
  }

  Future<RutinaProgresoDia> getProgresoRutina(int rutinaId) async {
    final todos = await getProgresoHoy();
    return todos[rutinaId] ?? const RutinaProgresoDia(pasoActual: 0, completada: false);
  }

  Future<void> guardarProgreso({
    required int rutinaId,
    required int pasoActual,
    required bool completada,
  }) async {
    final db = await _bd.db;
    await db.insert(
      'progreso_rutina',
      {
        'rutina_id': rutinaId,
        'fecha': _getFechaHoyClave(),
        'paso_actual': pasoActual,
        'completada': completada ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  Future<void> marcarCompletada({
    required int rutinaId,
    required int totalPasos,
  }) async {
    await guardarProgreso(
      rutinaId: rutinaId,
      pasoActual: totalPasos,
      completada: true,
    );
  }

  Future<Set<int>> getRutinasDesactivadas() async {
    try {
      final db = await _bd.db;
      final filas = await db.query('configuracion_rutina', columns: ['rutina_id'], where: 'activa = 0');
      return {for (final f in filas) f['rutina_id'] as int};
    } catch (_) {
      return {};
    }
  }

  Future<void> _guardarEstados(Map<int, bool> estados) async {
    final db = await _bd.db;
    final b = db.batch();
    estados.forEach((id, activa) {
      b.insert('configuracion_rutina', {'rutina_id': id, 'activa': activa ? 1 : 0},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await b.commit(noResult: true);
    notifyListeners();
  }

  Future<void> setRutinaActiva(int rutinaId, bool activa) => _guardarEstados({rutinaId: activa});

  Future<bool> isRutinaActiva(int rutinaId) async {
    final desactivadas = await getRutinasDesactivadas();
    return !desactivadas.contains(rutinaId);
  }

  Future<void> setRutinasActivas(Map<int, bool> estados) => _guardarEstados(estados);

  Future<void> setCategoriaActiva({
    required String categoria,
    required bool activa,
    required List<int> rutinaIdsDeCategoria,
  }) =>
      _guardarEstados({for (final id in rutinaIdsDeCategoria) id: activa});
}
