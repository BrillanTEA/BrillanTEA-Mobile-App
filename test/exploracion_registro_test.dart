import 'package:brillantea/presentacion/area_padres/tutoriales_page.dart';
import 'package:brillantea/presentacion/registro/bienvenida_page.dart';
import 'package:brillantea/presentacion/registro/perfil_nino_page.dart';
import 'package:brillantea/presentacion/registro/perfil_responsable_page.dart';
import 'package:brillantea/presentacion/registro/terminos_privacidad_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/exploracion.dart';
import 'soporte/pantallas.dart';

// Pruebas exploratorias automatizadas: ver test/soporte/exploracion.dart.
void main() {
  prepararExploracion();
  explorarPantalla('Bienvenida', () => const BienvenidaPage(saltarSplash: true), registrado: false);
  explorarPantalla('Términos y privacidad', () => const TerminosPrivacidadPage(), registrado: false);
  explorarPantalla('Perfil del responsable', () => const PerfilResponsablePage(), registrado: false);
  explorarPantalla('Perfil del niño', () => const PerfilNinoPage(perfilAdulto: adultoPrueba), registrado: false);
  explorarPantalla('Invitación a los tutoriales', () => const InvitacionPage());
}
