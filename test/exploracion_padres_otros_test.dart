import 'package:brillantea/presentacion/area_padres/area_padres_page.dart';
import 'package:brillantea/presentacion/area_padres/privacidad_datos_page.dart';
import 'package:brillantea/presentacion/area_padres/seguimiento_page.dart';
import 'package:brillantea/presentacion/area_padres/tutoriales_page.dart';
import 'package:brillantea/presentacion/premios/premios_page.dart';

import 'soporte/exploracion.dart';

// Pruebas exploratorias automatizadas: ver test/soporte/exploracion.dart.
void main() {
  prepararExploracion();
  explorarPantalla('Accesibilidad', () => const AccesibilidadPage(nombreNino: 'Mateo'));
  explorarPantalla('Ayuda y soporte', () => const AyudaSoportePage());
  explorarPantalla('Seguimiento', () => const SeguimientoPage(), conDatos: true);
  explorarPantalla('Seguimiento sin datos', () => const SeguimientoPage());
  explorarPantalla('Premios', () => const PremiosConfigPage());
  explorarPantalla('Tutoriales', () => const TutorialesPage(), conVoz: true);
  explorarPantalla('Privacidad y datos', () => const PrivacidadDatosPage());
}
