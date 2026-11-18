import 'package:brillantea/presentacion/inicio/inicio_page.dart';
import 'package:brillantea/presentacion/registro/bienvenida_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/pantallas.dart';

// Pantalla de carga con la app ya configurada (US1501).
// (Va en su propio archivo: cada archivo de pruebas usa una base de datos nueva.)

void main() {
  setUp(prepararPantallas);
  tearDown(limpiarPantallas);

  pantalla('con la app configurada lleva al Inicio', (tester) async {
    await conRegistro(tester);
    await abrirEncima(tester, const BienvenidaPage());
    await esperarHasta(tester, find.byType(InicioPage));
    expect(find.byType(InicioPage), findsOneWidget);
  });
}
