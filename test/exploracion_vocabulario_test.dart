import 'package:brillantea/presentacion/situaciones/situaciones_page.dart';
import 'package:brillantea/presentacion/vocabulario/vocabulario_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/exploracion.dart';

// Pruebas exploratorias automatizadas: ver test/soporte/exploracion.dart.
void main() {
  prepararExploracion();
  explorarPantalla('Vocabulario', () => const VocabularioPage(), conVoz: true);
  explorarPantalla('Situaciones', () => const SituacionesPage(), conVoz: true);
}
