import 'package:brillantea/presentacion/area_padres/privacidad_datos_page.dart';
import 'package:brillantea/presentacion/comun/pin_input_cuadros.dart';
import 'package:brillantea/presentacion/situaciones/situaciones_page.dart';
import 'package:brillantea/presentacion/vocabulario/vocabulario_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/pantallas.dart';

// Situaciones de principio a fin, cada categoría de Vocabulario, los documentos legales y la
// entrada de PIN por recuadros (RF-09, RF-14, US901).

void main() {
  setUp(prepararPantallas);
  tearDown(limpiarPantallas);

  pantalla('una situación se recorre hasta «¡Muy bien!», se lee otra vez y se elige otra', (tester) async {
    await conRegistro(tester);
    await activarVoz(tester);
    await abrir(tester, const SituacionesPage());
    await tocar(tester, find.text('Ir al doctor'));
    for (var paso = 0; paso < 15 && find.text('¡Muy bien!').evaluate().isEmpty; paso++) {
      if (!await tocarSiHay(tester, find.text('Siguiente'))) await tocarSiHay(tester, find.text('Terminar'));
    }
    expect(find.text('¡Muy bien!'), findsWidgets);
    await tocar(tester, find.text('Leer otra vez'));
    await tocarSiHay(tester, porEtiqueta('Volver'));
    await tocar(tester, find.text('Saludar'));
    for (var paso = 0; paso < 15 && find.text('¡Muy bien!').evaluate().isEmpty; paso++) {
      if (!await tocarSiHay(tester, find.text('Siguiente'))) await tocarSiHay(tester, find.text('Terminar'));
    }
    await tocarSiHay(tester, find.text('Otra situación'));
    expect(find.text('¿Qué quieres repasar?'), findsOneWidget);
    await desactivarVoz(tester);
  });

  pantalla('cada categoría de Vocabulario muestra y busca sus pictogramas', (tester) async {
    await conRegistro(tester);
    for (final categoria in ['Colores', 'Números', 'Letras', 'Frutas', 'Formas', 'Animales']) {
      final pila = ContadorRutas();
      await abrir(tester, const VocabularioPage(), observadores: [pila]);
      if (!await tocarSiHay(tester, find.text(categoria))) continue;
      if (find.byType(TextField).evaluate().isNotEmpty) {
        await escribir(tester, 0, 'a');
        await escribir(tester, 0, '');
      }
      await explorar(tester, pila, profundidad: 1, maxPorPantalla: 10);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  pantalla('los documentos legales se abren en una hoja y se cierran', (tester) async {
    await conRegistro(tester);
    await abrir(tester, const PrivacidadDatosPage());
    await tocar(tester, find.text('Términos y condiciones'));
    await tocar(tester, find.text('Entendido'));
    await tocar(tester, find.text('Política de privacidad'));
    await tocar(tester, porEtiqueta('Cerrar'));
    expect(find.text('Privacidad y datos'), findsWidgets);
  });

  pantalla('tocar un recuadro del PIN borra desde ese dígito', (tester) async {
    final control = TextEditingController();
    final cambios = <String>[];
    await abrir(
      tester,
      Scaffold(body: Center(child: PinInputCuadros(controller: control, onChanged: cambios.add))),
    );
    await tester.enterText(find.byType(TextField), '123');
    await esperar(tester, vueltas: 1);
    await tester.tapAt(tester.getTopLeft(find.byType(PinInputCuadros)) + const Offset(20, 20));
    await esperar(tester, vueltas: 1);
    expect(control.text.length, lessThan(3));
    expect(cambios, isNotEmpty);
  });
}
