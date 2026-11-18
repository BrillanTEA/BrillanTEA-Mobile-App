import 'package:brillantea/dominio/auth_service.dart';
import 'package:brillantea/presentacion/area_padres/area_padres_page.dart';
import 'package:brillantea/presentacion/area_padres/cambiar_pin_page.dart';
import 'package:brillantea/presentacion/area_padres/login_pin_page.dart';
import 'package:brillantea/presentacion/area_padres/perfil_guardado_page.dart';
import 'package:brillantea/presentacion/area_padres/privacidad_datos_page.dart';
import 'package:brillantea/presentacion/area_padres/restablecer_pin_page.dart';
import 'package:brillantea/presentacion/comun/dialogo_confirmacion.dart';
import 'package:brillantea/presentacion/registro/bienvenida_page.dart';
import 'package:brillantea/presentacion/registro/creando_espacio_page.dart';
import 'package:brillantea/presentacion/registro/nuevo_pin_registro_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/pantallas.dart';

// Flujos del adulto con datos reales en la base de prueba: acceso con PIN y su bloqueo,
// recuperación del PIN, creación del PIN al registrarse, cambio de PIN y borrado de los datos
// (RF-06, RF-08, US1003, US1007, US1201 a US1204).

Future<T?> _servicio<T>(WidgetTester tester, Future<T> Function() f) => tester.runAsync(f);

Finder _enDialogo(String texto) =>
    find.descendant(of: find.byType(Dialog), matching: find.text(texto));

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

      await escribir(tester, 0, ' maria ');
      await escribir(tester, 1, 'GOMEZ');
      await escribir(tester, 2, 'barranco');
      await tocar(tester, find.text('Reintentar'));
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
        await escribir(tester, 0, 'Rosa');
        await escribir(tester, 1, 'Pérez');
        await escribir(tester, 2, 'Lince');
        await tocar(tester, find.text(intento == 0 ? 'Verificar' : 'Reintentar'));
        await esperarHasta(tester,
            intento < 2 ? find.text('Respuestas incorrectas') : find.text('Opción bloqueada'));
      }
      expect(find.text('Opción bloqueada'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await esperar(tester);
      await tocar(tester, find.text('Entendido'));
    });
  });

  group('PIN del registro y cambio de PIN (US1202, US1204)', () {
    pantalla('«Creando el espacio» lleva a crear el PIN y el PIN guarda el registro', (tester) async {
      await abrir(tester, const CreandoEspacioPage(perfilAdulto: adultoPrueba, perfilNino: ninoPrueba));
      expect(find.textContaining('Mateo'), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
      await esperar(tester);
      expect(find.byType(NuevoPinRegistroPage), findsOneWidget);

      await tocar(tester, find.text('Guardar PIN'));
      expect(find.text('Por favor ingresa los 4 dígitos.'), findsOneWidget);
      await escribir(tester, 0, pinPrueba);
      await tocar(tester, find.text('Guardar PIN'));
      await esperarHasta(tester, find.text('¡PIN guardado!'));
      expect(await _servicio(tester, () => AuthService().isConfigured()), isTrue);
      expect(await _servicio(tester, () => AuthService().verificarPin(pinPrueba)), isTrue);
      await tocar(tester, find.text('Continuar'));
    });

    pantalla('el PIN nuevo de 4 dígitos reemplaza al anterior', (tester) async {
      await conRegistro(tester);
      await abrirEncima(tester, const CambiarPinPage());
      await escribir(tester, 0, '13');
      await escribir(tester, 0, '1357');
      await tocar(tester, find.text('Guardar PIN'));
      await esperarHasta(tester, find.text('Abrir pantalla'));
      expect(find.byType(CambiarPinPage), findsNothing);
      expect(await _servicio(tester, () => AuthService().verificarPin('1357')), isTrue);
    });

    pantalla('«Perfil guardado» confirma el nombre del niño', (tester) async {
      await abrirEncima(tester, const PerfilGuardadoPage(nombreNino: 'Lucía'));
      expect(find.textContaining('Lucía'), findsWidgets);
      expect(find.text('¡Perfil guardado!'), findsOneWidget);
      await tocar(tester, find.text('Ir a Área de padres'));
    });

    pantalla('«Perfil guardado» sin nombre usa uno por defecto', (tester) async {
      await abrirEncima(tester, const PerfilGuardadoPage(nombreNino: '  '));
      expect(find.textContaining('Mateo'), findsWidgets);
    });
  });

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

  group('Diálogo de confirmación', () {
    for (final tipo in TipoDialogo.values) {
      pantalla('el diálogo «${tipo.name}» devuelve la opción elegida', (tester) async {
        bool? primero;
        bool? segundo;
        await abrir(
          tester,
          Builder(
            builder: (context) => Scaffold(
              body: Column(children: [
                TextButton(
                  onPressed: () async => primero = await mostrarDialogoConfirmacion(context,
                      tipo: tipo,
                      titulo: 'Título',
                      texto: 'Texto',
                      primario: 'Sí, guardar',
                      secundario: 'No'),
                  child: const Text('Abrir 1'),
                ),
                TextButton(
                  onPressed: () async => segundo = await mostrarDialogoConfirmacion(context,
                      tipo: tipo,
                      titulo: 'Título',
                      texto: 'Texto',
                      primario: 'Sí, guardar',
                      secundario: 'No',
                      secundarioRojo: true),
                  child: const Text('Abrir 2'),
                ),
              ]),
            ),
          ),
        );
        await tocar(tester, find.text('Abrir 1'));
        await tocar(tester, find.text('Sí, guardar'));
        expect(primero, isTrue);
        await tocar(tester, find.text('Abrir 2'));
        await tocar(tester, find.text('No'));
        expect(segundo, isFalse);
      });
    }
  });
}
