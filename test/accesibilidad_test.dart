import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:brillantea/datos/base_datos.dart';
import 'package:brillantea/dominio/accesibilidad_service.dart';
import 'package:brillantea/main.dart';

void main() {
  late Directory temporal;
  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    temporal =
        await Directory.systemTemp.createTemp('brillantea_accessibility_');
    await databaseFactory.setDatabasesPath(temporal.path);
  });
  tearDown(() async {
    await BaseDatos().borrarTodo();
    await temporal.delete(recursive: true);
  });
  testWidgets(
      'Accesibilidad textScaler changes when setTamanoTextoIndex is called',
      (tester) async {
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      final acc = AccesibilidadService();
      await acc.init();

      await tester.pumpWidget(const SpikeApp());
      await tester.pump();

      // Check initial factor
      expect(acc.factorEscala, 1.0);

      // Change to Grande
      await acc.setTamanoTextoIndex(2);
      await tester.pump();

      expect(acc.factorEscala, 1.30);
      final context = tester.element(find.byType(Scaffold).first);
      expect(MediaQuery.textScalerOf(context).scale(10), 13);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
