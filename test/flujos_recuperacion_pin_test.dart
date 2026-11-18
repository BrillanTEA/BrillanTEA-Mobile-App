import 'package:brillantea/dominio/auth_service.dart';
import 'package:brillantea/presentacion/area_padres/restablecer_pin_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/pantallas.dart';

// Flujos del adulto con datos reales en la base de prueba: acceso con PIN y su bloqueo,
// recuperación del PIN, creación del PIN al registrarse, cambio de PIN y borrado de los datos
// (RF-06, RF-08, US1003, US1007, US1201 a US1204).

Future<T> _servicio<T>(WidgetTester tester, Future<T> Function() f) => enApp(tester, f);

void main() {
  setUp(prepararPantallas);
  tearDown(limpiarPantallas);

  group('Recuperación del PIN (US1203)', () {
    pantalla('pide las tres respuestas, cuenta los intentos y crea un PIN nuevo', (tester) async {
      var restablecido = false;
      await conRegistro(tester);
      await abrirEncima(tester, RestablecerPinPage(onPinRestablecido: () => restablecido = true));
      expect(find.text('Verifica que eres tú'), findsOneWidget);

      await tocar(tester, find.text('Verificar'));
      expect(find.text('Falta escribir tu nombre.'), findsOneWidget);
      expect(find.text('Falta escribir tu apellido.'), findsOneWidget);
      expect(find.text('Falta escribir tu ciudad.'), findsOneWidget);

      await escribir(tester, 0, 'Rosa');
      await escribir(tester, 1, 'Pérez');
      await escribir(tester, 2, 'Lince');
      await tocar(tester, find.text('Verificar'));
      await esperarHasta(tester, find.text('Respuestas incorrectas'));
      expect(find.text('Te quedan 2 intentos'), findsOneWidget);

      // «Reintentar» limpia las respuestas; luego se escriben otra vez y se verifica.
      await tocar(tester, find.text('Reintentar'));
      await escribir(tester, 0, ' maria ');
      await escribir(tester, 1, 'GOMEZ');
      await escribir(tester, 2, 'barranco');
      await tocar(tester, find.text('Verificar'));
      await esperarHasta(tester, find.text('¡Identidad verificada!'));
      expect(find.text('¡Identidad verificada!'), findsOneWidget);

      await tocar(tester, find.text('Crear nuevo PIN'));
      expect(find.text('Crea un nuevo PIN'), findsOneWidget);
      await escribir(tester, 0, '12');
      await tocar(tester, find.text('Guardar PIN'));
      expect(find.text('El PIN debe tener 4 dígitos.'), findsOneWidget);
      await escribir(tester, 0, '4321');
      await tocar(tester, find.text('Guardar PIN'));
      await esperarHasta(tester, find.text('¡PIN guardado!'));
      expect(find.text('¡PIN guardado!'), findsOneWidget);
      await tocar(tester, find.text('Ingresar PIN'));
      expect(restablecido, isTrue);
      expect(await _servicio(tester, () => AuthService().verificarPin('4321')), isTrue);
    });

    pantalla('tres respuestas equivocadas bloquean la opción', (tester) async {
      await conRegistro(tester);
      await abrirEncima(tester, RestablecerPinPage(onPinRestablecido: () {}));
      for (var intento = 0; intento < 3; intento++) {
        if (find.text('Reintentar').evaluate().isNotEmpty) await tocar(tester, find.text('Reintentar'));
        await escribir(tester, 0, 'Rosa');
        await escribir(tester, 1, 'Pérez');
        await escribir(tester, 2, 'Lince');
        await tocar(tester, find.text('Verificar'));
        await esperarHasta(tester,
            intento < 2 ? find.text('Respuestas incorrectas') : find.text('Opción bloqueada'));
      }
      expect(find.text('Opción bloqueada'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await esperar(tester);
      await tocar(tester, find.text('Entendido'));
    });
  });
}
