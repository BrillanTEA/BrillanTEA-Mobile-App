import 'package:sqflite/sqflite.dart';

import '../datos/base_datos.dart';

/// Guarda qué tutoriales ya vio el adulto (tabla tutorial_visto, BaseDatos v4).
class TutorialesService {
  static final TutorialesService _instance = TutorialesService._internal();
  factory TutorialesService() => _instance;
  TutorialesService._internal();

  Future<Set<String>> vistos() async {
    try {
      final f = await (await BaseDatos().db).query('tutorial_visto', columns: ['clave']);
      return f.map((e) => e['clave'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> marcarVisto(String clave) async {
    try {
      await (await BaseDatos().db).insert(
        'tutorial_visto',
        {'clave': clave, 'ts': DateTime.now().millisecondsSinceEpoch},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (_) {}
  }
}
