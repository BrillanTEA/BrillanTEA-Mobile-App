import 'package:brillantea/presentacion/registro/bienvenida_page.dart';
import 'package:brillantea/presentacion/registro/terminos_privacidad_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/pantallas.dart';

// Pantalla de carga la primera vez (US1501).
// (Va en su propio archivo: cada archivo de pruebas usa una base de datos nueva.)

void main() {
  setUp(prepararPantallas);
  tearDown(limpiarPantallas);

  pantalla('la primera vez lleva a «¡Hola!» y a los términos', (tester) async {
    await abrirEncima(tester, const BienvenidaPage());
    await esperarHasta(tester, find.text('¡Hola!'));
    expect(find.text('¡Hola!'), findsOneWidget);
    await tocar(tester, find.text('Comenzar'));
    expect(find.byType(TerminosPrivacidadPage), findsOneWidget);
  });

}
