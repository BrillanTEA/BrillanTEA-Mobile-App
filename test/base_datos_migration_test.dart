import 'dart:io';

import 'package:brillantea/datos/base_datos.dart';
import 'package:brillantea/dominio/auth_service.dart';
import 'package:brillantea/dominio/documentos_legales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporal;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    temporal = await Directory.systemTemp.createTemp('brillantea_migration_');
    await databaseFactory.setDatabasesPath(temporal.path);
  });
  tearDown(() async {
    await BaseDatos().borrarTodo();
    await temporal.delete(recursive: true);
  });

  test(
      'v6 to v8 preserves existing records and does not invent a consent version',
      () async {
    final bd = BaseDatos();
    var db = await bd.db;
    // v6 has the same tables, without the two columns introduced in v7 and v8.
    await db.execute('ALTER TABLE configuracion_premios DROP COLUMN periodo');
    await db.execute('ALTER TABLE ajuste DROP COLUMN acuerdo_version');
    await db.setVersion(6);
    await db.insert('perfil_nino',
        {'id': 1, 'nombre': 'Ejemplo', 'edad': 8, 'avatar': 'avatar_1'});
    await db.update(
        'ajuste',
        {
          'configurada': 1,
          'acuerdo_privacidad': 1,
          'acuerdo_fecha': '2026-11-14T12:00:00',
          'pin_hash': 'existing-hash',
          'pin_salt': 'existing-salt',
        },
        where: 'id = 1');
    await db.insert('rutina', {'id': 999, 'nombre': 'Fixture'});
    await db.insert('progreso_rutina', {
      'rutina_id': 999,
      'fecha': '2026-11-14',
      'paso_actual': 2,
      'completada': 1,
    });
    final tables = (await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))
        .map((row) => row['name'] as String)
        .toList();
    final before = <String, List<Map<String, Object?>>>{};
    for (final table in tables) {
      before[table] = await db.query(table);
    }
    await bd.cerrar();
    db = await bd.db;
    expect(await db.getVersion(), 8);
    for (final table in tables) {
      final columns =
          before[table]!.isEmpty ? null : before[table]!.first.keys.toList();
      expect(await db.query(table, columns: columns), before[table],
          reason: table);
    }
    expect(
        (await db.query('configuracion_premios')).single['periodo'], 'semanal');
    expect((await db.query('ajuste')).single['acuerdo_version'], isNull);
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });

  test('fresh v8 records the accepted document version and date', () async {
    final db = await BaseDatos().db;
    expect(await db.getVersion(), 8);
    await AuthService().setAcuerdoPrivacidadAceptado(true);
    final registro = await AuthService().getRegistroAceptacion();
    expect(registro.version, versionDocumentosLegales);
    expect(registro.fecha, isNotNull);
  });
}
