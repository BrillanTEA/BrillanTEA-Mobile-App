import 'package:brillantea/dominio/favoritos_service.dart';
import 'package:brillantea/dominio/registro_uso_service.dart';
import 'package:brillantea/dominio/rutinas_app.dart';
import 'package:brillantea/datos/base_datos.dart';
import 'package:brillantea/presentacion/area_padres/area_padres_page.dart';
import 'package:brillantea/presentacion/area_padres/cambiar_pin_page.dart';
import 'package:brillantea/presentacion/area_padres/categoria_rutinas_config_page.dart';
import 'package:brillantea/presentacion/area_padres/configuracion_cuenta_page.dart';
import 'package:brillantea/presentacion/area_padres/login_pin_page.dart';
import 'package:brillantea/presentacion/area_padres/perfil_menor_page.dart';
import 'package:brillantea/presentacion/area_padres/privacidad_datos_page.dart';
import 'package:brillantea/presentacion/area_padres/rutinas_activas_config_page.dart';
import 'package:brillantea/presentacion/area_padres/seguimiento_page.dart';
import 'package:brillantea/presentacion/area_padres/tutoriales_page.dart';
import 'package:brillantea/presentacion/calma/calma_page.dart';
import 'package:brillantea/presentacion/comunicacion/comunicacion_page.dart';
import 'package:brillantea/presentacion/inicio/inicio_page.dart';
import 'package:brillantea/presentacion/premios/premios_page.dart';
import 'package:brillantea/presentacion/registro/bienvenida_page.dart';
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

import 'soporte/pantallas.dart';

// Pruebas exploratorias automatizadas (monkey testing dirigido): en cada pantalla se escribe en los
// campos de texto y se toca, uno por uno, cada control; en las pantallas y diálogos que se abren se
// repite lo mismo un nivel más. La prueba falla si alguna pantalla lanza un error (los desbordes de
// diseño de la fuente de pruebas se ignoran). La Cámara se excluye porque necesita el hardware.

final _camara = RegExp(r'^Cámara$');

/// Datos de uso para que Seguimiento, Favoritos y Premios muestren contenido.
Future<void> _conDatosDeUso(WidgetTester tester) async {
  await tester.runAsync(() async {
    final db = await BaseDatos().db;
    for (final r in rutinasApp) {
      await db.rawInsert('INSERT OR IGNORE INTO rutina (id, nombre) VALUES (?, ?)', [r.id, r.nombre]);
    }
    final registro = RegistroUsoService();
    await registro.registrar(RegistroUsoService.rutinaInicio, '1', etiqueta: 'Lavado de manos');
    await registro.registrar(RegistroUsoService.rutinaFin, '1', etiqueta: 'Lavado de manos');
    await registro.registrar(RegistroUsoService.peticion, 'agua', etiqueta: 'Quiero agua');
    await registro.registrar(RegistroUsoService.emocion, 'triste', etiqueta: 'Triste');
    await registro.registrar(RegistroUsoService.calma, 'respirar', etiqueta: 'Respirar');
    await registro.agregarNota('Hoy estuvo tranquilo.');
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
}

void _explorar(String nombre, Widget Function() pagina,
    {bool registrado = true, bool conDatos = false, bool conVoz = false, int profundidad = 2}) {
  pantalla('exploración: $nombre', (tester) async {
    if (registrado) await conRegistro(tester);
    if (conDatos) await _conDatosDeUso(tester);
    if (conVoz) await activarVoz(tester);
    final pila = ContadorRutas();
    await abrir(tester, _Base(pagina), observadores: [pila]);
    pila.rutas = 1;
    Future<void> reabrir() => tocar(tester, find.text('Abrir pantalla'));
    await reabrir();
    final toques =
        await explorar(tester, pila, profundidad: profundidad, evitar: _camara, reabrir: reabrir);
    expect(toques, greaterThan(0));
    if (conVoz) await desactivarVoz(tester);
  }, timeout: const Timeout(Duration(minutes: 8)));
}

/// Pantalla base: la pantalla explorada se abre encima, así sus botones «Volver» tienen a dónde volver.
class _Base extends StatelessWidget {
  const _Base(this.pagina);

  final Widget Function() pagina;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pagina())),
            child: const Text('Abrir pantalla'),
          ),
        ),
      );
}

void main() {
  setUp(() async {
    await prepararPantallas();
    FavoritosService().limpiarMemoria();
  });
  tearDown(limpiarPantallas);

  group('Registro y bienvenida', () {
    _explorar('Bienvenida', () => const BienvenidaPage(saltarSplash: true), registrado: false);
    _explorar('Bienvenida con pantalla de carga', () => const BienvenidaPage(), registrado: false);
    _explorar('Términos y privacidad', () => const TerminosPrivacidadPage(), registrado: false);
    _explorar('Perfil del responsable', () => const PerfilResponsablePage(), registrado: false);
    _explorar('Perfil del niño', () => const PerfilNinoPage(perfilAdulto: adultoPrueba), registrado: false);
    _explorar('Invitación a los tutoriales', () => const InvitacionPage());
  });

  group('Módulos del niño', () {
    _explorar('Inicio', () => const InicioPage(), conDatos: true);
    _explorar('Comunicación', () => const ComunicacionPage(), conVoz: true);
    _explorar('Vocabulario', () => const VocabularioPage(), conVoz: true);
    _explorar('Emociones', () => const EmocionesPage(), conVoz: true);
    _explorar('Favoritos', () => const FavoritosPage(), conDatos: true, conVoz: true);
    _explorar('Situaciones', () => const SituacionesPage(), conVoz: true);
    _explorar('Calma', () => const CalmaPage(), conVoz: true);
    _explorar('Rutinas por categoría', () => const RutinasCategoriasPage(), conDatos: true);
    for (final categoria in ['Higiene', 'Ropa', 'Comida', 'Hogar']) {
      _explorar('Rutinas de $categoria', () => RutinasPage(categoriaInicial: categoria),
          conDatos: true, conVoz: true);
    }
    _explorar('Mis premios', () => const MisPremiosPage(), conDatos: true);
  });

  group('Área de padres', () {
    _explorar('Acceso con PIN', () => const LoginPinPage());
    _explorar('Área de padres', () => const AreaPadresPage(), conDatos: true);
    _explorar('Configuración de cuenta', () => const ConfiguracionCuentaPage());
    _explorar('Cambiar PIN', () => const CambiarPinPage());
    _explorar('Rutinas activas', () => const RutinasActivasConfigPage(), conDatos: true);
    for (final categoria in ['Higiene', 'Ropa', 'Comida', 'Hogar']) {
      _explorar('Rutinas activas de $categoria', () => CategoriaRutinasConfigPage(categoria: categoria),
          conDatos: true);
    }
    _explorar('Perfil del menor', () => const PerfilMenorPage(perfilInicial: ninoPrueba));
    _explorar('Perfil de la menor', () => const PerfilMenorPage(perfilInicial: ninaPrueba));
    _explorar('Accesibilidad', () => const AccesibilidadPage(nombreNino: 'Mateo'));
    _explorar('Ayuda y soporte', () => const AyudaSoportePage());
    _explorar('Seguimiento', () => const SeguimientoPage(), conDatos: true);
    _explorar('Seguimiento sin datos', () => const SeguimientoPage());
    _explorar('Premios', () => const PremiosConfigPage());
    _explorar('Tutoriales', () => const TutorialesPage(), conVoz: true);
    _explorar('Privacidad y datos', () => const PrivacidadDatosPage());
  });
}
