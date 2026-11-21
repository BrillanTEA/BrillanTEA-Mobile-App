import 'package:brillantea/presentacion/premios/premios_page.dart';
import 'package:brillantea/presentacion/rutinas/rutinas_categorias_page.dart';
import 'package:brillantea/presentacion/rutinas/rutinas_page.dart';

import 'soporte/exploracion.dart';

// Pruebas exploratorias automatizadas: ver test/soporte/exploracion.dart.
void main() {
  prepararExploracion();
  explorarPantalla('Rutinas por categoría', () => const RutinasCategoriasPage(), conDatos: true);
  for (final categoria in ['Higiene', 'Ropa', 'Comida', 'Hogar']) {
    explorarPantalla('Rutinas de $categoria', () => RutinasPage(categoriaInicial: categoria),
        conDatos: true, conVoz: true);
  }
  explorarPantalla('Mis premios', () => const MisPremiosPage(), conDatos: true);
}
