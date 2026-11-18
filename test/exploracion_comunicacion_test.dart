import 'package:brillantea/presentacion/comunicacion/comunicacion_page.dart';
import 'package:brillantea/presentacion/vocabulario/emociones_page.dart';
import 'package:brillantea/presentacion/vocabulario/favoritos_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/exploracion.dart';

// Pruebas exploratorias automatizadas: ver test/soporte/exploracion.dart.
void main() {
  prepararExploracion();
  explorarPantalla('Comunicación', () => const ComunicacionPage(), conVoz: true);
  explorarPantalla('Emociones', () => const EmocionesPage(), conVoz: true);
  explorarPantalla('Favoritos', () => const FavoritosPage(), conDatos: true, conVoz: true);
}
