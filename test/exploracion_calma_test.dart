import 'package:brillantea/presentacion/calma/calma_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/exploracion.dart';

// Pruebas exploratorias automatizadas: ver test/soporte/exploracion.dart.
void main() {
  prepararExploracion();
  explorarPantalla('Calma', () => const CalmaPage(), conVoz: true);
}
