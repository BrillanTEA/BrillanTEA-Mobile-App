import 'package:brillantea/presentacion/inicio/inicio_page.dart';

import 'soporte/exploracion.dart';

// Pruebas exploratorias automatizadas: ver test/soporte/exploracion.dart.
void main() {
  prepararExploracion();
  explorarPantalla('Inicio', () => const InicioPage(), conDatos: true);
}
