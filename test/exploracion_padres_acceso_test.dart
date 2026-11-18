import 'package:brillantea/presentacion/area_padres/area_padres_page.dart';
import 'package:brillantea/presentacion/area_padres/cambiar_pin_page.dart';
import 'package:brillantea/presentacion/area_padres/configuracion_cuenta_page.dart';
import 'package:brillantea/presentacion/area_padres/login_pin_page.dart';
import 'package:brillantea/presentacion/area_padres/rutinas_activas_config_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/exploracion.dart';

// Pruebas exploratorias automatizadas: ver test/soporte/exploracion.dart.
void main() {
  prepararExploracion();
  explorarPantalla('Acceso con PIN', () => const LoginPinPage());
  explorarPantalla('Área de padres', () => const AreaPadresPage(), conDatos: true);
  explorarPantalla('Configuración de cuenta', () => const ConfiguracionCuentaPage());
  explorarPantalla('Cambiar PIN', () => const CambiarPinPage());
  explorarPantalla('Rutinas activas', () => const RutinasActivasConfigPage(), conDatos: true);
}
