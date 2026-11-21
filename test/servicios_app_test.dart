import 'dart:convert';

import 'package:brillantea/datos/base_datos.dart';
import 'package:brillantea/dominio/accesibilidad_service.dart';
import 'package:brillantea/dominio/catalogo_service.dart';
import 'package:brillantea/dominio/sesion_calma.dart';
import 'package:brillantea/dominio/tutoriales_service.dart';
import 'package:brillantea/infraestructura/stats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'soporte/entorno_prueba.dart';

Future<int> _contar(String tabla) async {
  final filas = await (await BaseDatos().db).rawQuery('SELECT COUNT(*) AS n FROM $tabla');
  return filas.single['n'] as int;
}

void main() {
  final entorno = EntornoPrueba();
  setUp(() => entorno.preparar());
  tearDown(() => entorno.limpiar());

  group('Repositorio local SQLite (US401, US1205)', () {
    test('crea las 15 tablas con claves foráneas y carga el catálogo una sola vez', () async {
      final db = await BaseDatos().db;
      final tablas = (await db.rawQuery(
              "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'"))
          .map((f) => f['name'])
          .toSet();
      expect(tablas, hasLength(15));
      expect(
          tablas,
          containsAll(<String>[
            'pictograma', 'rutina', 'objeto', 'cierre_rutina', 'perfil_adulto', 'perfil_nino',
            'ajuste', 'preferencia_accesibilidad', 'configuracion_rutina', 'favorito',
            'progreso_rutina', 'registro_uso', 'nota_especialista', 'configuracion_premios',
            'tutorial_visto',
          ]));
      expect((await db.rawQuery('PRAGMA foreign_keys')).single.values.single, 1);
      expect(await _contar('rutina'), 5);
      expect(await _contar('objeto'), 36); // 35 objetos detectables y «colegio»
      expect(await _contar('cierre_rutina'), 5);

      final huella = (await db.query('ajuste')).single['catalogo_hash'];
      expect(huella, isNotNull);
      await BaseDatos().cerrar();
      final otraVez = await BaseDatos().db;
      expect((await otraVez.query('ajuste')).single['catalogo_hash'], huella);
      expect(await otraVez.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    });

    test('migra una sola vez los datos que versiones anteriores guardaban en SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'auth_configurada': true,
        'auth_acuerdo_privacidad_aceptado': true,
        'auth_acuerdo_privacidad_fecha': '2026-10-01T10:00:00',
        'auth_pin_hash': 'hash-antiguo',
        'auth_pin_salt': 'sal-antigua',
        'auth_failed_attempts': 1,
        'auth_perfil_adulto':
            jsonEncode({'nombres': 'Rosa', 'apellidoPaterno': 'Quispe', 'ciudadNacimiento': 'Lince'}),
        'auth_perfil_nino': jsonEncode({'nombre': 'Lucía', 'edad': '7', 'avatar': 'nina'}),
        'acc_tamano_texto_idx': 2,
        'acc_vibracion': false,
        'acc_bloqueo_activo': true,
        'rutinas_desactivadas_ids_v1': <String>['2'],
        'rutinas_progreso_2026-10-01': jsonEncode({
          '1': {'pasoActual': 4, 'completada': true},
        }),
        'brillantea_favoritos_v2': jsonEncode([
          {'id': 'perro', 'nombre': 'Perro', 'contadorUso': 3},
        ]),
        'otra_clave': 'se conserva',
      });

      final db = await BaseDatos().db;
      final ajuste = (await db.query('ajuste')).single;
      expect(ajuste['configurada'], 1);
      expect(ajuste['acuerdo_privacidad'], 1);
      expect(ajuste['pin_hash'], 'hash-antiguo');
      expect(ajuste['intentos_pin'], 1);
      expect(ajuste['pantalla_fijada'], 1);
      expect(ajuste['preferencias_migradas'], 1);
      expect((await db.query('perfil_adulto')).single['ciudad_nacimiento'], 'Lince');
      final nino = (await db.query('perfil_nino')).single;
      expect(nino['edad'], 7);
      expect(nino['avatar'], 'nina');
      final preferencias = (await db.query('preferencia_accesibilidad')).single;
      expect(preferencias['tamano_texto'], 2);
      expect(preferencias['vibracion'], 0);
      expect((await db.query('configuracion_rutina')).single['rutina_id'], 2);
      final progreso = (await db.query('progreso_rutina')).single;
      expect(progreso['fecha'], '2026-10-01');
      expect(progreso['completada'], 1);
      expect((await db.query('favorito')).single['contador_uso'], 3);
      expect((await SharedPreferences.getInstance()).getKeys(), {'otra_clave'});
    });

    test('borrar la base deja solo los valores iniciales', () async {
      final db = await BaseDatos().db;
      await db.update('ajuste', {'configurada': 1}, where: 'id = 1');
      await BaseDatos().borrarTodo();
      final nueva = await BaseDatos().db;
      expect((await nueva.query('ajuste')).single['configurada'], 0);
    });
  });

  group('Catálogo (RF-02, RF-03)', () {
    test('lee las rutinas, los 35 objetos y el pictograma de contexto desde SQLite', () async {
      final catalogo = CatalogoService();
      await catalogo.load();
      expect(catalogo.isLoaded, isTrue);
      expect(catalogo.items.where((i) => i.esRutina), hasLength(5));
      expect(catalogo.items.where((i) => !i.esRutina && i.idModelo != null), hasLength(35));

      final jabon = catalogo.findPorEtiqueta(' JABON ');
      expect(jabon?.clave, 'jabon');
      expect(jabon?.assetPath, startsWith('assets/pictogramas/'));
      expect(catalogo.findByClave('rutina_1')?.nombre, 'Lavado de manos');
      expect(catalogo.findByClave('colegio')?.categoria, 'Contexto');
      expect(catalogo.findPorEtiqueta(null), isNull);
      expect(catalogo.findPorEtiqueta('dinosaurio'), isNull);
    });
  });

  group('Accesibilidad (US1011, US1102)', () {
    test('empieza con baja estimulación y guarda cada ajuste en SQLite', () async {
      final acc = AccesibilidadService();
      await acc.init();
      expect(acc.tamanoTextoIndex, 1);
      expect(acc.factorEscala, 1.0);
      expect(acc.sonidosApp, isFalse);
      expect(acc.vibracion, isTrue);
      expect(acc.leerVozAlta, isFalse);
      expect(acc.tutorialCamara, isTrue);
      expect(acc.pantallaBloqueada, isFalse);

      await acc.setTamanoTextoIndex(0);
      expect(acc.factorEscala, 0.85);
      await acc.setSonidosApp(true);
      await acc.setVibracion(false);
      await acc.setTutorialCamara(false);
      await acc.setPantallaBloqueada(true);
      acc.feedbackInteraccion();
      acc.vibrar(fuerte: true);
      acc.reproducirSonido();

      final db = await BaseDatos().db;
      final fila = (await db.query('preferencia_accesibilidad')).single;
      expect(fila['tamano_texto'], 0);
      expect(fila['sonidos'], 1);
      expect(fila['vibracion'], 0);
      expect(fila['tutorial_camara'], 0);
      expect((await db.query('ajuste')).single['pantalla_fijada'], 1);

      // Los valores por defecto vuelven al leer una base nueva.
      await BaseDatos().borrarTodo();
      await acc.init();
      expect(acc.tamanoTextoIndex, 1);
      expect(acc.sonidosApp, isFalse);
    });

    test('la lectura en voz alta usa el motor de voz solo si está activada', () async {
      final acc = AccesibilidadService();
      await acc.init();
      await acc.hablar('No se dice');
      expect(entorno.voz.where((l) => l.method == 'speak'), isEmpty);

      await acc.setLeerVozAlta(true);
      await acc.hablar('Hola');
      expect(entorno.voz.where((l) => l.method == 'speak').map((l) => l.arguments), contains('Hola'));

      await acc.setLeerVozAlta(false);
      expect(acc.leerVozAlta, isFalse);
    });
  });

  group('Tutoriales, Calma y medición de latencia', () {
    test('cada tutorial se marca como visto una sola vez (US1502)', () async {
      final tutoriales = TutorialesService();
      expect(await tutoriales.vistos(), isEmpty);
      await tutoriales.marcarVisto('camara');
      await tutoriales.marcarVisto('camara');
      await tutoriales.marcarVisto('calma');
      expect(await tutoriales.vistos(), {'camara', 'calma'});
    });

    test('la sesión de Calma recuerda la emoción, los intentos y cómo se siente (US1303)', () {
      SesionCalma.iniciar(emocionId: 'triste', emocionNombre: 'Triste');
      SesionCalma.registrarIntento('Respirar despacito');
      SesionCalma.registrarIntento('Respirar despacito');
      SesionCalma.registrarIntento('Descansar');
      expect(SesionCalma.emocionNombre, 'Triste');
      expect(SesionCalma.intentos, ['Respirar despacito', 'Descansar']);
      expect(SesionCalma.textoEstado, 'Pidió ayuda');
      SesionCalma.estadoActual = 'mejor';
      expect(SesionCalma.textoEstado, 'Se siente mejor');
      SesionCalma.estadoActual = 'igual';
      expect(SesionCalma.textoEstado, 'Sigue igual');
      SesionCalma.estadoActual = 'peor';
      expect(SesionCalma.textoEstado, 'Se siente peor');

      SesionCalma.iniciar();
      expect(SesionCalma.emocionId, isNull);
      expect(SesionCalma.intentos, isEmpty);
      expect(SesionCalma.estadoActual, isNull);
    });

    test('las estadísticas de latencia usan una ventana móvil (RNF-01)', () {
      final stats = LatencyStats(3);
      expect(stats.mean, 0);
      expect(stats.p95, 0);
      expect(stats.last, 0);
      for (final ms in [10.0, 20.0, 30.0, 40.0]) {
        stats.add(ms);
      }
      expect(stats.count, 3);
      expect(stats.last, 40);
      expect(stats.mean, 30);
      expect(stats.p50, 30);
      expect(stats.all, hasLength(4));
      expect(LatencyStats.percentile([5, 1, 3], 100), 5);
      stats.clear();
      expect(stats.count, 0);
      expect(stats.all, isEmpty);
    });
  });
}
