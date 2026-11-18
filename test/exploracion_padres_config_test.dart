import 'package:brillantea/presentacion/area_padres/categoria_rutinas_config_page.dart';
import 'package:brillantea/presentacion/area_padres/perfil_menor_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/exploracion.dart';
import 'soporte/pantallas.dart';

// Pruebas exploratorias automatizadas: ver test/soporte/exploracion.dart.
void main() {
  prepararExploracion();
  for (final categoria in ['Higiene', 'Ropa', 'Comida', 'Hogar']) {
    explorarPantalla('Rutinas activas de $categoria', () => CategoriaRutinasConfigPage(categoria: categoria),
        conDatos: true);
  }
  explorarPantalla('Perfil del menor', () => const PerfilMenorPage(perfilInicial: ninoPrueba));
  explorarPantalla('Perfil de la menor', () => const PerfilMenorPage(perfilInicial: ninaPrueba));
}
