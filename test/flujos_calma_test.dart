import 'package:brillantea/dominio/sesion_calma.dart';
import 'package:brillantea/presentacion/calma/calma_page.dart';
import 'package:brillantea/presentacion/vocabulario/emociones_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/pantallas.dart';

// Flujos completos del niño con datos reales en la base de prueba: una rutina de principio a fin
// con temporizador y medalla, «Ir a rutina» desde un objeto, los ejercicios de Calma con sus tres
// respuestas y el reporte de seguimiento en PDF (RF-03, RF-04, RF-15, RF-18, RF-19).

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
  });
}
