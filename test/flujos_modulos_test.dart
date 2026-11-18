import 'dart:io';

import 'package:brillantea/dominio/registro_uso_service.dart';
import 'package:brillantea/dominio/reporte_service.dart';
import 'package:brillantea/dominio/rutinas_app.dart';
import 'package:brillantea/dominio/rutinas_service.dart';
import 'package:brillantea/dominio/sesion_calma.dart';
import 'package:brillantea/datos/base_datos.dart';
import 'package:brillantea/dominio/auth_service.dart';
import 'package:brillantea/presentacion/calma/calma_page.dart';
import 'package:brillantea/presentacion/premios/premios_page.dart';
import 'package:brillantea/presentacion/rutinas/rutinas_page.dart';
import 'package:brillantea/presentacion/vocabulario/emociones_page.dart';
import 'package:brillantea/presentacion/vocabulario/vocabulario_modelo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

import 'soporte/pantallas.dart';

// Flujos completos del niño con datos reales en la base de prueba: una rutina de principio a fin
// con temporizador y medalla, «Ir a rutina» desde un objeto, los ejercicios de Calma con sus tres
// respuestas y el reporte de seguimiento en PDF (RF-03, RF-04, RF-15, RF-18, RF-19).

/// Las rutinas 1 a 5 vienen del catálogo; se aseguran para cumplir las claves foráneas.
Future<void> _conRutinas(WidgetTester tester) async {
  await tester.runAsync(() async {
    final db = await BaseDatos().db;
    for (final r in rutinasApp) {
      await db.rawInsert('INSERT OR IGNORE INTO rutina (id, nombre) VALUES (?, ?)', [r.id, r.nombre]);
    }
  });
}

/// Hace avanzar el reloj de 1 en 1 segundo hasta que aparezca [buscado].
Future<void> _avanzarHasta(WidgetTester tester, Finder buscado, {int maxSegundos = 400}) async {
  for (var s = 0; s < maxSegundos && buscado.evaluate().isEmpty; s++) {
    await tester.pump(const Duration(seconds: 1));
    if (s % 20 == 0) await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  }
  await esperar(tester);
}

void main() {
  setUp(prepararPantallas);
  tearDown(limpiarPantallas);

  group('Rutina guiada de principio a fin (RF-04, RF-19, US501 a US506)', () {
    pantalla('Lavado de manos: pasos, temporizador, medalla y vuelta a la lista', (tester) async {
      await conRegistro(tester);
      await _conRutinas(tester);
      await activarVoz(tester);
      await abrir(tester, const RutinasPage(categoriaInicial: 'Higiene'));
      await tocar(tester, find.text('Lavado de manos'));
      expect(find.text('0 de 4 pasos'), findsWidgets);
      await tocar(tester, find.text('¡Empezar!'));
      expect(find.text('AHORA'), findsWidgets);
      expect(entorno.voz.where((l) => l.method == 'speak'), isNotEmpty);

      for (var paso = 0; paso < 6; paso++) {
        if (porEtiqueta('Pausar').evaluate().isNotEmpty) {
          await tocar(tester, porEtiqueta('Pausar'));
          await tocar(tester, porEtiqueta('Seguir'));
          await tocar(tester, porEtiqueta('Empezar de nuevo'));
          await _avanzarHasta(tester, find.text('¡Listo!'), maxSegundos: 30);
          expect(find.text('¡Listo!'), findsWidgets);
        }
        final fin = find.text('¡Terminé la rutina!');
        if (fin.evaluate().isNotEmpty) {
          await tocar(tester, fin);
          break;
        }
        await tocar(tester, find.text('¡Terminé este paso!'));
      }
      await esperarHasta(tester, find.text('¡Ganaste una medalla!'));
      expect(find.text('¡Ganaste una medalla!'), findsWidgets);
      final eventos = await enApp(tester, () => RegistroUsoService().eventos(DateTime(2000), DateTime(2100)));
      expect(eventos.map((e) => e.tipo), containsAll(<String>['rutina_inicio', 'rutina_paso', 'rutina_fin']));

      await tocar(tester, find.text('Ver mis premios'));
      expect(find.byType(MisPremiosPage), findsOneWidget);
      Navigator.of(tester.element(find.byType(MisPremiosPage))).pop();
      await esperar(tester);
      await tocar(tester, find.text('Volver a mis rutinas'));
      expect(find.text('4 de 4 pasos'), findsWidgets);

      // Repasar una rutina ya cumplida hoy no da otra medalla.
      await tocar(tester, find.text('Lavado de manos'));
      expect(find.text('¡Rutina cumplida hoy!'), findsOneWidget);
      await desactivarVoz(tester);
    });

    pantalla('una rutina empezada se retoma en el paso guardado y se puede retroceder', (tester) async {
      await conRegistro(tester);
      await _conRutinas(tester);
      await tester.runAsync(
          () => RutinasService().guardarProgreso(rutinaId: 1, pasoActual: 2, completada: false));
      await abrir(tester, const RutinasPage());
      expect(find.textContaining('CONTINUAR'), findsWidgets);
      await escribir(tester, 0, 'lav');
      await tocar(tester, find.text('Lavado de manos'));
      expect(find.text('Continuar en paso 3'), findsOneWidget);
      await tocar(tester, find.text('Continuar en paso 3'));
      // Volver desde un paso intermedio regresa al paso anterior y guarda el avance.
      await tocar(tester, porEtiqueta('Volver'));
      await tocar(tester, porEtiqueta('Volver'));
      await tocar(tester, porEtiqueta('Volver'));
      final progreso = await enApp(tester, () => RutinasService().getProgresoRutina(1));
      expect(progreso.completada, isFalse);
    });

    pantalla('«Ir a rutina» lista las rutinas del objeto y abre la elegida (RF-03)', (tester) async {
      await conRegistro(tester);
      await _conRutinas(tester);
      final rutinas = await tester.runAsync(() => rutinasQueEmpiezanCon('assets/pictogramas/cano_2414.png'));
      await abrir(tester,
          RutinasConObjetoPage(nombreObjeto: 'Caño', assetObjeto: 'assets/pictogramas/cano_2414.png', rutinas: rutinas!));
      expect(find.text('Con esto empieza 1 rutina'), findsOneWidget);
      await tocar(tester, find.text('Lavado de manos'));
      expect(find.byType(RutinasPage), findsOneWidget);
      expect(find.text('¡Empezar!'), findsOneWidget);
    });

    pantalla('con varias rutinas del objeto muestra el plural', (tester) async {
      await conRegistro(tester);
      await _conRutinas(tester);
      await abrir(tester,
          RutinasConObjetoPage(nombreObjeto: 'Varios', assetObjeto: 'x.png', rutinas: rutinasApp.take(2).toList()));
      expect(find.text('Con esto empiezan 2 rutinas'), findsOneWidget);
      await tocar(tester, porEtiqueta('Volver'));
    });
  });

  group('Calma (RF-18, US1301 a US1304)', () {
    pantalla('Respirar y «Mejor» llevan a «¡Qué bien!» y a elegir otra emoción', (tester) async {
      await conRegistro(tester);
      SesionCalma.iniciar(emocionId: 'triste', emocionNombre: 'Triste');
      await activarVoz(tester);
      await abrir(tester, const CalmaPage());
      await tocar(tester, find.text('Respirar'));
      expect(find.text('Inhala'), findsWidgets);
      await _avanzarHasta(tester, find.text('Mejor'));
      await tocar(tester, find.text('Mejor'));
      expect(SesionCalma.estadoActual, 'mejor');
      await tocar(tester, find.text('Elegir otra emoción'));
      expect(find.byType(EmocionesPage), findsOneWidget);
      await desactivarVoz(tester);
    });

    pantalla('Aprieta y suelta e «Igual» permiten hacer calma otra vez', (tester) async {
      await conRegistro(tester);
      await abrir(tester, const CalmaPage());
      await tocar(tester, find.text('Aprieta y suelta'));
      expect(find.text('Aprieta'), findsWidgets);
      await _avanzarHasta(tester, find.text('Igual'));
      await tocar(tester, find.text('Igual'));
      expect(find.text('Sigues igual'), findsOneWidget);
      await tocar(tester, find.text('Hacer calma otra vez'));
      expect(find.text('¿Qué quieres hacer?'), findsOneWidget);
    });

    pantalla('«Peor» pide ayuda y el adulto ve el aviso con lo que intentó el niño', (tester) async {
      await conRegistro(tester, nino: ninaPrueba);
      SesionCalma.iniciar(emocionId: 'enojado', emocionNombre: 'Enojado');
      await abrir(tester, const CalmaPage());
      await tocar(tester, find.text('Respirar'));
      await _avanzarHasta(tester, find.text('Peor'));
      await tocar(tester, find.text('Peor'));
      expect(find.textContaining('Necesito'), findsWidgets);
      await tocar(tester, find.text('Soy el adulto · Ver aviso'));
      expect(find.text('Lucía necesita ayuda'), findsOneWidget);
      expect(find.textContaining('enojada'), findsWidgets);
      expect(find.text('Respirar despacito'), findsWidgets);
      await tocar(tester, find.text('Ya estoy con Lucía'));
      await tocar(tester, find.text('Listo'));
    });

    pantalla('Descansar y «Pedir ayuda» desde «Sigues igual»', (tester) async {
      await conRegistro(tester);
      SesionCalma.iniciar();
      await abrir(tester, const CalmaPage());
      await tocar(tester, find.text('Descansar'));
      expect(find.text('Ya descansé'), findsOneWidget);
      await tocar(tester, find.text('Ya descansé'));
      await tocar(tester, find.text('Igual'));
      await tocar(tester, find.text('Pedir ayuda'));
      await tocar(tester, find.text('Soy el adulto · Ver aviso'));
      expect(find.text('Entró directo a Calma'), findsOneWidget);
    });

    pantalla('«Parar» detiene el ejercicio y vuelve al menú', (tester) async {
      await abrirEncima(tester, const CalmaPage());
      await tocar(tester, find.text('Respirar'));
      await tester.pump(const Duration(seconds: 3));
      await tocar(tester, find.text('Parar'));
      expect(find.text('¿Qué quieres hacer?'), findsOneWidget);
    });
  });

  group('Formas del vocabulario', () {
    pantalla('cada forma se dibuja y se vuelve a dibujar al cambiar', (tester) async {
      Widget formas(List<FormaVocabulario> lista) => MaterialApp(
            home: Scaffold(
              body: Wrap(children: [for (final f in lista) DibujoForma(forma: f, tamano: 60)]),
            ),
          );
      await tester.pumpWidget(formas(FormaVocabulario.values));
      expect(find.byType(DibujoForma), findsNWidgets(FormaVocabulario.values.length));
      await tester.pumpWidget(formas(FormaVocabulario.values.reversed.toList()));
      expect(find.byType(CustomPaint), findsWidgets);

      const elemento = ElementoVocabulario(id: 'v_rojo', nombre: 'ROJO', silabas: 'RO · JO', fraseVoz: 'Rojo');
      final favorito = elemento.toFavoritoItem('Colores');
      expect(favorito.modulo, 'Vocabulario');
      expect(favorito.silabas, 'RO · JO');
    });
  });

  group('Reporte de seguimiento en PDF (RF-15, RNF-04)', () {
    test('genera el PDF en la carpeta temporal, lo comparte y borra las copias', () async {
      await AuthService().actualizarPerfilNino(ninoPrueba);
      final registro = RegistroUsoService();
      await registro.registrar(RegistroUsoService.rutinaInicio, '1', etiqueta: 'Lavado de manos');
      await registro.registrar(RegistroUsoService.rutinaFin, '1', etiqueta: 'Lavado de manos');
      await registro.registrar(RegistroUsoService.peticion, 'agua', etiqueta: 'Quiero agua');
      await registro.registrar(RegistroUsoService.respuesta, 'si', etiqueta: 'Sí');
      await registro.registrar(RegistroUsoService.emocion, 'triste', etiqueta: 'Triste');
      await registro.registrar(RegistroUsoService.objeto, 'cano', etiqueta: 'Caño');
      await registro.agregarNota('Durmió poco.');

      final carpeta = await getTemporaryDirectory();
      final viejo = File('${carpeta.path}/reporte_brillantea_viejo.pdf')..writeAsStringSync('x');
      viejo.setLastModifiedSync(DateTime.now().subtract(const Duration(minutes: 30)));
      final reciente = File('${carpeta.path}/reporte_brillantea_reciente.pdf')..writeAsStringSync('x');
      final ajeno = File('${carpeta.path}/otro_archivo.txt')..writeAsStringSync('x');

      await ReporteService.limpiarViejos();
      expect(viejo.existsSync(), isFalse);
      expect(reciente.existsSync(), isTrue);

      expect(await ReporteService.generarYCompartir(), isTrue);
      final pdfs = carpeta
          .listSync()
          .whereType<File>()
          .where((f) => f.uri.pathSegments.last.startsWith('reporte_brillantea_2'))
          .toList();
      expect(pdfs, isNotEmpty);
      expect(pdfs.first.readAsBytesSync().take(4), '%PDF'.codeUnits);

      await ReporteService.borrarTodos();
      expect(
          carpeta.listSync().whereType<File>().where((f) => f.uri.pathSegments.last.startsWith('reporte_brillantea_')),
          isEmpty);
      expect(ajeno.existsSync(), isTrue);
      ajeno.deleteSync();
    });

    test('sin perfil ni datos el reporte usa textos por defecto', () async {
      expect(await ReporteService.generarYCompartir(), isTrue);
      await ReporteService.borrarTodos();
    });
  });
}
