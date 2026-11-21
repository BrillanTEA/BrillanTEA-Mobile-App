import 'dart:io';

import 'package:brillantea/datos/base_datos.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Entorno común de las pruebas: la base SQLite real de la app en una carpeta temporal
/// (sqflite_common_ffi), SharedPreferences en memoria y el motor de voz de Android simulado.
/// Cada prueba empieza con la app recién instalada.
class EntornoPrueba {
  Directory? _carpeta;

  /// Llamadas que la app hizo al motor de voz (setLanguage, speak, stop…).
  final List<MethodCall> voz = [];

  Future<void> preparar({Map<String, Object> preferencias = const {}}) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(preferencias);
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    _carpeta = await Directory.systemTemp.createTemp('brillantea_prueba_');
    await databaseFactory.setDatabasesPath(_carpeta!.path);
    voz.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (llamada) async {
        voz.add(llamada);
        return 1;
      },
    );
  }

  Future<void> limpiar() async {
    await BaseDatos().borrarTodo();
    final carpeta = _carpeta;
    if (carpeta != null && await carpeta.exists()) {
      await carpeta.delete(recursive: true);
    }
  }
}
