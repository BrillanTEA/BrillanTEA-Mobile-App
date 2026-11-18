import 'package:brillantea/dominio/auth_service.dart';
import 'package:brillantea/dominio/favoritos_service.dart';
import 'package:brillantea/dominio/registro_uso_service.dart';
import 'package:brillantea/presentacion/area_padres/area_padres_page.dart';
import 'package:brillantea/presentacion/area_padres/cambiar_pin_page.dart';
import 'package:brillantea/presentacion/area_padres/categoria_rutinas_config_page.dart';
import 'package:brillantea/presentacion/area_padres/configuracion_cuenta_page.dart';
import 'package:brillantea/presentacion/area_padres/login_pin_page.dart';
import 'package:brillantea/presentacion/area_padres/perfil_menor_page.dart';
import 'package:brillantea/presentacion/area_padres/privacidad_datos_page.dart';
import 'package:brillantea/presentacion/area_padres/restablecer_pin_page.dart';
import 'package:brillantea/presentacion/area_padres/rutinas_activas_config_page.dart';
import 'package:brillantea/presentacion/area_padres/seguimiento_page.dart';
import 'package:brillantea/presentacion/area_padres/tutoriales_page.dart';
import 'package:brillantea/presentacion/calma/calma_page.dart';
import 'package:brillantea/presentacion/comunicacion/comunicacion_page.dart';
import 'package:brillantea/presentacion/inicio/inicio_page.dart';
import 'package:brillantea/presentacion/premios/premios_page.dart';
import 'package:brillantea/presentacion/registro/perfil_nino_page.dart';
import 'package:brillantea/presentacion/registro/perfil_responsable_page.dart';
import 'package:brillantea/presentacion/registro/terminos_privacidad_page.dart';
import 'package:brillantea/presentacion/rutinas/rutinas_categorias_page.dart';
import 'package:brillantea/presentacion/rutinas/rutinas_page.dart';
import 'package:brillantea/presentacion/situaciones/situaciones_page.dart';
import 'package:brillantea/presentacion/vocabulario/emociones_page.dart';
import 'package:brillantea/presentacion/vocabulario/favoritos_page.dart';
import 'package:brillantea/presentacion/vocabulario/vocabulario_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/entorno_prueba.dart';

// Pruebas de widgets: abren cada pantalla en un celular de 412 × 915 con la base SQLite de prueba
// y recorren los flujos principales. La fuente de pruebas de Flutter dibuja cada letra como un
// cuadrado (más ancha que la fuente real), así que los avisos de desborde de texto se ignoran;
// cualquier otro error de la pantalla hace fallar la prueba.

const _adulto = PerfilAdulto(
  nombres: 'María',
  apellidoPaterno: 'Gómez',
  apellidoMaterno: '',
  diaNacimiento: '12',
  mesNacimiento: 'Mayo',
  anioNacimiento: '1991',
  ciudadNacimiento: 'Barranco',
  edad: '35',
  sexo: 'Femenino',
  parentesco: 'Mamá',
);
const _nino = PerfilNino(nombre: 'Mateo', edad: 8, avatar: 'nino');

Future<void> _esperar(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _abrir(WidgetTester tester, Widget pagina) async {
  await tester.binding.setSurfaceSize(const Size(412, 915));
  await tester.runAsync(() async {
    await tester.pumpWidget(MaterialApp(home: pagina));
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await _esperar(tester);
}

Future<void> _tocar(WidgetTester tester, Finder destino) async {
  await tester.ensureVisible(destino.first);
  await tester.pump();
  await tester.tap(destino.first, warnIfMissed: false);
  await _esperar(tester);
}

Future<void> _conPerfiles(WidgetTester tester) async {
  await tester.runAsync(() async {
    await AuthService().actualizarPerfilAdulto(_adulto);
    await AuthService().actualizarPerfilNino(_nino);
    await AuthService().setAcuerdoPrivacidadAceptado(true);
  });
}

/// Prueba de una pantalla: ignora solo los desbordes de diseño y cierra la pantalla al final
/// para que se cancelen sus temporizadores.
void _pantalla(String descripcion, Future<void> Function(WidgetTester tester) cuerpo) {
  testWidgets(descripcion, (tester) async {
    final previo = FlutterError.onError;
    FlutterError.onError = (detalle) {
      if (detalle.exceptionAsString().contains('overflowed')) return;
      previo?.call(detalle);
    };
    try {
      await cuerpo(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    } finally {
      FlutterError.onError = previo;
      await tester.binding.setSurfaceSize(null);
    }
  });
}

void main() {
  final entorno = EntornoPrueba();
  setUp(() async {
    await entorno.preparar();
    FavoritosService().limpiarMemoria();
  });
  tearDown(() => entorno.limpiar());

  group('Pantallas que se abren sin errores', () {
    final pantallas = <String, Widget Function()>{
      'Inicio': () => const InicioPage(),
      'Términos y privacidad': () => const TerminosPrivacidadPage(),
      'Perfil del responsable': () => const PerfilResponsablePage(),
      'Perfil del niño': () => const PerfilNinoPage(perfilAdulto: _adulto),
      'Acceso con PIN': () => const LoginPinPage(),
      'Verifica que eres tú': () => RestablecerPinPage(onPinRestablecido: () {}),
      'Área de padres': () => const AreaPadresPage(),
      'Configuración de cuenta': () => const ConfiguracionCuentaPage(),
      'Cambiar PIN': () => const CambiarPinPage(),
      'Rutinas activas': () => const RutinasActivasConfigPage(),
      'Rutinas activas de Higiene': () => const CategoriaRutinasConfigPage(categoria: 'Higiene'),
      'Perfil del menor': () => const PerfilMenorPage(perfilInicial: _nino),
      'Accesibilidad': () => const AccesibilidadPage(nombreNino: 'Mateo'),
      'Ayuda y soporte': () => const AyudaSoportePage(),
      'Seguimiento': () => const SeguimientoPage(),
      'Mis premios': () => const MisPremiosPage(),
      'Rutinas': () => const RutinasCategoriasPage(),
      'Rutina de Higiene': () => const RutinasPage(categoriaInicial: 'Higiene'),
      'Vocabulario': () => const VocabularioPage(),
      'Favoritos': () => const FavoritosPage(),
      'Calma': () => const CalmaPage(),
      'Situaciones': () => const SituacionesPage(),
    };
    for (final pantalla in pantallas.entries) {
      _pantalla('${pantalla.key} se dibuja con datos de prueba', (tester) async {
        await _conPerfiles(tester);
        await _abrir(tester, pantalla.value());
        expect(find.byType(Scaffold), findsWidgets);
      });
    }
  });

  group('Flujos de pantalla', () {
    _pantalla('Privacidad y datos muestra el consentimiento otorgado con su versión (US901)', (tester) async {
      await _conPerfiles(tester);
      await _abrir(tester, const PrivacidadDatosPage());
      expect(find.text('CONSENTIMIENTO OTORGADO'), findsOneWidget);
      expect(find.text('Términos y condiciones'), findsWidgets);
      expect(find.text('Retirar consentimiento'), findsOneWidget);
      expect(find.text('Borrar los datos'), findsOneWidget);
      expect(find.textContaining('Versión 1.0'), findsOneWidget);
      await _tocar(tester, find.text('Política de privacidad'));
    });

    _pantalla('Premios muestra el rango de la meta del período elegido (US1402)', (tester) async {
      await _abrir(tester, const PremiosConfigPage());
      expect(find.text('Premios'), findsWidgets);
      expect(find.text('De 10 a 35 medallas por semana'), findsOneWidget);
      expect(find.text('Así lo verá el niño'), findsOneWidget);
    });

    _pantalla('Mis premios muestra la meta de la semana (US1401)', (tester) async {
      await _abrir(tester, const MisPremiosPage());
      expect(find.text('Mis premios'), findsWidgets);
      expect(find.text('Meta de la semana: 20 medallas'), findsOneWidget);
    });

    _pantalla('el tutorial de la Cámara se recorre en 7 pantallas (US1502)', (tester) async {
      await _abrir(tester, const TutorialesPage());
      expect(find.text('Tutoriales'), findsWidgets);
      await _tocar(tester, find.text('Cámara'));
      await _tocar(tester, find.text('Empezar'));
      for (var paso = 1; paso <= 5; paso++) {
        await _tocar(tester, find.text('Siguiente'));
      }
      expect(find.text('Terminar'), findsOneWidget);
      expect(find.text('Ver otra vez'), findsOneWidget);
      await _tocar(tester, find.text('Terminar'));
      expect(find.text('Aprende para qué sirve cada módulo.'), findsOneWidget);
    });

    _pantalla('la invitación a los tutoriales lleva al Inicio con «Más tarde» (US1501)', (tester) async {
      await _conPerfiles(tester);
      await _abrir(tester, const InvitacionPage());
      expect(find.text('Conoce BrillanTEA'), findsOneWidget);
      await _tocar(tester, find.text('Más tarde'));
      expect(find.byType(InicioPage), findsOneWidget);
    });

    _pantalla('Responder dice «Sí» y lo guarda en el registro de uso (US605)', (tester) async {
      await _abrir(tester, const ComunicacionPage());
      expect(find.text('Pedir algo'), findsOneWidget);
      expect(find.text('Armar mi frase'), findsOneWidget);
      await _tocar(tester, find.text('Responder'));
      await _tocar(tester, find.text('Sí'));
      final eventos = await tester.runAsync(
          () => RegistroUsoService().eventos(DateTime(2000), DateTime(2100)));
      expect(eventos!.map((e) => e.clave), contains('si'));
      expect(entorno.voz.where((l) => l.method == 'speak'), isNotEmpty);
    });

    _pantalla('Pedir algo muestra las categorías de necesidades (US601)', (tester) async {
      await _abrir(tester, const ComunicacionPage());
      await _tocar(tester, find.text('Pedir algo'));
      expect(find.text('Comer'), findsWidgets);
      expect(find.text('Baño'), findsWidgets);
    });

    _pantalla('Armar mi frase se abre desde Comunicación (US603)', (tester) async {
      await _abrir(tester, const ComunicacionPage());
      await _tocar(tester, find.text('Armar mi frase'));
      expect(find.byType(ComunicacionPage), findsOneWidget);
    });

    _pantalla('Emociones dice la emoción al tocarla (US703)', (tester) async {
      await _conPerfiles(tester);
      await _abrir(tester, const EmocionesPage());
      expect(find.text('Alegre'), findsWidgets);
      await _tocar(tester, find.text('Alegre'));
      expect(entorno.voz.where((l) => l.method == 'speak'), isNotEmpty);
    });

    _pantalla('Situaciones abre «Ir al doctor» (US801)', (tester) async {
      await _abrir(tester, const SituacionesPage());
      await _tocar(tester, find.text('Ir al doctor'));
      final siguiente = find.text('Siguiente');
      if (siguiente.evaluate().isNotEmpty) {
        await _tocar(tester, siguiente);
      }
      expect(find.byType(SituacionesPage), findsOneWidget);
    });

    _pantalla('Rutinas muestra las cuatro categorías (US501)', (tester) async {
      await _abrir(tester, const RutinasCategoriasPage());
      for (final categoria in ['Higiene', 'Ropa', 'Comida', 'Hogar']) {
        expect(find.text(categoria), findsWidgets, reason: categoria);
      }
    });

    _pantalla('Vocabulario abre la categoría Animales (US701)', (tester) async {
      await _abrir(tester, const VocabularioPage());
      await _tocar(tester, find.text('Animales'));
      expect(find.byType(VocabularioPage), findsOneWidget);
    });

    _pantalla('Ayuda y soporte muestra los dos correos de soporte (RF-17)', (tester) async {
      await _abrir(tester, const AyudaSoportePage());
      expect(find.textContaining('u201714765@upc.edu.pe'), findsWidgets);
      expect(find.textContaining('u202214784@upc.edu.pe'), findsWidgets);
    });

    _pantalla('Área de padres abre Privacidad y datos (US1007)', (tester) async {
      await _conPerfiles(tester);
      await _abrir(tester, const AreaPadresPage());
      await _tocar(tester, find.text('Privacidad y datos'));
      expect(find.byType(PrivacidadDatosPage), findsOneWidget);
    });

    _pantalla('Favoritos muestra lo que el niño marcó (US706)', (tester) async {
      await tester.runAsync(() async {
        await FavoritosService().init();
        await FavoritosService().toggleFavorito(FavoritoItem(
          id: 'vocab_animales_perro',
          nombre: 'PERRO',
          modulo: 'Vocabulario',
          colorModuloValue: 0xFF3D6D7E,
          assetPath: 'assets/images/vocab_perro.png',
          fraseVoz: 'Perro',
        ));
      });
      await _abrir(tester, const FavoritosPage());
      expect(find.textContaining('PERRO'), findsWidgets);
    });
  });
}
