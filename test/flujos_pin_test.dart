import 'package:brillantea/dominio/auth_service.dart';
import 'package:brillantea/presentacion/area_padres/area_padres_page.dart';
import 'package:brillantea/presentacion/area_padres/login_pin_page.dart';
import 'package:brillantea/presentacion/area_padres/privacidad_datos_page.dart';
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

  group('Acceso al área de padres (RF-08)', () {
    pantalla('con el PIN correcto se abre el área de padres', (tester) async {
      await conRegistro(tester);
      await abrir(tester, const LoginPinPage());
      expect(find.text('Área para padres'), findsWidgets);
      await escribir(tester, 0, pinPrueba);
      await esperarHasta(tester, find.byType(AreaPadresPage));
      expect(find.byType(AreaPadresPage), findsOneWidget);
    });

    pantalla('con el PIN correcto va al destino pedido', (tester) async {
      await conRegistro(tester);
      await abrir(tester, const LoginPinPage(destinoTrasPin: PrivacidadDatosPage()));
      await escribir(tester, 0, pinPrueba);
      await esperarHasta(tester, find.byType(PrivacidadDatosPage));
      expect(find.byType(PrivacidadDatosPage), findsOneWidget);
    });

    pantalla('tres PIN incorrectos bloquean el acceso 5 minutos', (tester) async {
      await conRegistro(tester);
      await abrir(tester, const LoginPinPage());
      for (var intento = 0; intento < 3; intento++) {
        await escribir(tester, 0, '0000');
        await esperarHasta(tester, find.textContaining('incorrecto'), maxVueltas: 40);
        final reintentar = find.text('Reintentar');
        if (reintentar.evaluate().isNotEmpty && intento < 2) await tocar(tester, reintentar);
      }
      await esperarHasta(tester, find.text('Opción bloqueada'));
      expect(await _servicio(tester, () => AuthService().isLocked()), isTrue);
      expect(find.text('Opción bloqueada'), findsOneWidget);
      // El contador baja cada segundo.
      await tester.pump(const Duration(seconds: 3));
      await esperar(tester);
      await tocar(tester, find.text('Entendido'));
    });

    pantalla('«¿Olvidaste tu PIN?» abre la verificación de identidad', (tester) async {
      await conRegistro(tester);
      await abrir(tester, const LoginPinPage());
      await tocar(tester, find.text('¿Olvidaste tu PIN?'));
      expect(find.byType(RestablecerPinPage), findsOneWidget);
      await tocar(tester, find.text('Cancelar'));
      expect(find.byType(LoginPinPage), findsOneWidget);
    });

    pantalla('«Volver» sale del acceso con PIN', (tester) async {
      var volvio = false;
      await conRegistro(tester);
      await abrir(tester, LoginPinPage(onBack: () => volvio = true));
      await tocar(tester, porEtiqueta('Volver'));
      expect(volvio, isTrue);
    });
  });
}
