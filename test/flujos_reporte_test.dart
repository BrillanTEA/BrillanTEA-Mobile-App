import 'dart:io';
import 'package:brillantea/dominio/registro_uso_service.dart';
import 'package:brillantea/dominio/reporte_service.dart';
import 'package:brillantea/dominio/auth_service.dart';
import 'package:brillantea/presentacion/vocabulario/vocabulario_modelo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'soporte/pantallas.dart';

// Flujos completos del niño con datos reales en la base de prueba: una rutina de principio a fin
// con temporizador y medalla, «Ir a rutina» desde un objeto, los ejercicios de Calma con sus tres
// respuestas y el reporte de seguimiento en PDF (RF-03, RF-04, RF-15, RF-18, RF-19).

void main() {
  setUp(prepararPantallas);
  tearDown(limpiarPantallas);

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
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('sin perfil ni datos el reporte usa textos por defecto', () async {
      expect(await ReporteService.generarYCompartir(), isTrue);
      await ReporteService.borrarTodos();
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
