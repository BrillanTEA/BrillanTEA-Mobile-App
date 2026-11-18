import 'package:brillantea/dominio/auth_service.dart';
import 'package:brillantea/presentacion/comun/pin_input_cuadros.dart';
import 'package:brillantea/presentacion/registro/creando_espacio_page.dart';
import 'package:brillantea/presentacion/registro/nuevo_pin_registro_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/pantallas.dart';

// Registro: «Creando el espacio» lleva a crear el PIN, que guarda el primer uso (US1202, DEF-18).
// (Va en su propio archivo: cada archivo de pruebas usa una base de datos nueva.)

Future<T> _servicio<T>(WidgetTester tester, Future<T> Function() f) => enApp(tester, f);

void main() {
  setUp(prepararPantallas);
  tearDown(limpiarPantallas);

  pantalla('«Creando el espacio» lleva a crear el PIN y el PIN guarda el registro', (tester) async {
    await abrirEncima(tester, const CreandoEspacioPage(perfilAdulto: adultoPrueba, perfilNino: ninoPrueba));
    expect(find.textContaining('Mateo'), findsWidgets);
    await esperarHasta(tester, find.text('Crea un nuevo PIN'));
    expect(find.byType(NuevoPinRegistroPage), findsOneWidget);
    await esperar(tester);

    // Se pulsa el botón llamando a su acción: durante la transición de pantalla el botón todavía
    // no tiene posición en la prueba, aunque ya está construido.
    Future<void> guardar() async {
      tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Guardar PIN').last).onPressed!();
      await esperar(tester);
    }

    await guardar();
    expect(find.text('Por favor ingresa los 4 dígitos.'), findsOneWidget);
    tester.widget<PinInputCuadros>(find.byType(PinInputCuadros, skipOffstage: false)).controller.text = pinPrueba;
    await guardar();
    await esperarHasta(tester, find.text('¡PIN guardado!'));
    expect(await _servicio(tester, () => AuthService().isConfigured()), isTrue);
    expect(await _servicio(tester, () => AuthService().verificarPin(pinPrueba)), isTrue);
    await tocar(tester, find.text('Continuar'));
  });

}
