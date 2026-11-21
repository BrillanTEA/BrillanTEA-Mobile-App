import 'package:brillantea/dominio/auth_service.dart';
import 'package:brillantea/presentacion/area_padres/privacidad_datos_page.dart';
import 'package:brillantea/presentacion/registro/bienvenida_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/pantallas.dart';

// Flujos del adulto con datos reales en la base de prueba: acceso con PIN y su bloqueo,
// recuperación del PIN, creación del PIN al registrarse, cambio de PIN y borrado de los datos
// (RF-06, RF-08, US1003, US1007, US1201 a US1204).

Future<T> _servicio<T>(WidgetTester tester, Future<T> Function() f) => enApp(tester, f);

Finder _enDialogo(String texto) =>
    find.descendant(of: find.byType(Dialog), matching: find.text(texto));

void main() {
  setUp(prepararPantallas);
  tearDown(limpiarPantallas);

  group('Borrado de los datos y retiro del consentimiento (US1007, US901)', () {
    pantalla('con PIN incorrecto no borra y con el correcto deja la app como nueva', (tester) async {
      await conRegistro(tester);
      await abrir(tester, const PrivacidadDatosPage());
      await tocar(tester, find.text('Borrar los datos'));
      expect(find.text('¿Borrar los datos?'), findsOneWidget);
      expect(find.text('Ingresa tu PIN para confirmar'), findsOneWidget);

      await escribir(tester, 0, '0000');
      await tocar(tester, _enDialogo('Borrar los datos'));
      await esperarHasta(tester, find.text('PIN incorrecto.'));
      expect(find.text('PIN incorrecto.'), findsOneWidget);
      expect(await _servicio(tester, () => AuthService().isConfigured()), isTrue);

      await escribir(tester, 0, pinPrueba);
      await tocar(tester, _enDialogo('Borrar los datos'));
      await esperarHasta(tester, find.byType(BienvenidaPage));
      expect(find.byType(BienvenidaPage), findsOneWidget);
      expect(await _servicio(tester, () => AuthService().isConfigured()), isFalse);
    });

    pantalla('retirar el consentimiento se puede cancelar', (tester) async {
      await conRegistro(tester);
      await abrir(tester, const PrivacidadDatosPage());
      await tocar(tester, find.text('Retirar consentimiento'));
      expect(find.text('¿Retirar tu consentimiento?'), findsOneWidget);
      await tocar(tester, find.text('Cancelar'));
      expect(find.byType(Dialog), findsNothing);
      expect(await _servicio(tester, () => AuthService().isConfigured()), isTrue);
    });

    pantalla('tres PIN incorrectos en el borrado bloquean el PIN', (tester) async {
      await conRegistro(tester);
      await abrir(tester, const PrivacidadDatosPage());
      await tocar(tester, find.text('Retirar consentimiento'));
      for (var intento = 0; intento < 4; intento++) {
        await escribir(tester, 0, '0000');
        await tocar(tester, _enDialogo('Retirar consentimiento'));
        await esperarHasta(tester, find.textContaining(RegExp('PIN incorrecto|intentos|bloqueado')));
      }
      expect(find.textContaining(RegExp('Demasiados intentos|PIN bloqueado')), findsOneWidget);
    });
  });
}
