import 'package:brillantea/dominio/auth_service.dart';
import 'package:brillantea/presentacion/area_padres/cambiar_pin_page.dart';
import 'package:brillantea/presentacion/area_padres/perfil_guardado_page.dart';
import 'package:brillantea/presentacion/comun/dialogo_confirmacion.dart';
import 'package:brillantea/presentacion/inicio/inicio_page.dart';
import 'package:brillantea/presentacion/registro/bienvenida_page.dart';
import 'package:brillantea/presentacion/registro/creando_espacio_page.dart';
import 'package:brillantea/presentacion/registro/nuevo_pin_registro_page.dart';
import 'package:brillantea/presentacion/registro/terminos_privacidad_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/pantallas.dart';

// Flujos del adulto con datos reales en la base de prueba: acceso con PIN y su bloqueo,
// recuperación del PIN, creación del PIN al registrarse, cambio de PIN y borrado de los datos
// (RF-06, RF-08, US1003, US1007, US1201 a US1204).

Future<T> _servicio<T>(WidgetTester tester, Future<T> Function() f) => enApp(tester, f);

void main() {
  setUp(prepararPantallas);
  tearDown(limpiarPantallas);

  group('PIN del registro y cambio de PIN (US1202, US1204)', () {
    pantalla('«Creando el espacio» lleva a crear el PIN y el PIN guarda el registro', (tester) async {
      await abrirEncima(tester, const CreandoEspacioPage(perfilAdulto: adultoPrueba, perfilNino: ninoPrueba));
      expect(find.textContaining('Mateo'), findsWidgets);
      await esperarHasta(tester, find.text('Crea un nuevo PIN'));
      expect(find.byType(NuevoPinRegistroPage), findsOneWidget);
      await esperar(tester);

      final guardar = find.widgetWithText(ElevatedButton, 'Guardar PIN');
      await tester.tap(guardar.last, warnIfMissed: false);
      await esperar(tester);
      expect(find.text('Por favor ingresa los 4 dígitos.'), findsOneWidget);
      await escribir(tester, 0, pinPrueba);
      await tester.tap(guardar.last, warnIfMissed: false);
      await esperar(tester);
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
      await esperarHastaQueNo(tester, find.byType(CambiarPinPage));
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

  group('Pantalla de carga (US1501)', () {
    pantalla('la primera vez lleva a «¡Hola!» y a los términos', (tester) async {
      await abrirEncima(tester, const BienvenidaPage());
      await esperarHasta(tester, find.text('¡Hola!'));
      expect(find.text('¡Hola!'), findsOneWidget);
      await tocar(tester, find.text('Comenzar'));
      expect(find.byType(TerminosPrivacidadPage), findsOneWidget);
    });

    pantalla('con la app configurada lleva al Inicio', (tester) async {
      await conRegistro(tester);
      await abrirEncima(tester, const BienvenidaPage());
      await esperarHasta(tester, find.byType(InicioPage));
      expect(find.byType(InicioPage), findsOneWidget);
    });
  });
}
