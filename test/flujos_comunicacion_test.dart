import 'package:brillantea/dominio/registro_uso_service.dart';
import 'package:brillantea/presentacion/comunicacion/comunicacion_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/pantallas.dart';

// Comunicación de principio a fin: Armar mi frase en tres pasos (con Borrar y sin paso 3),
// Responder «No» y las subcategorías de Pedir algo (RF-05, RF-12, RF-13).

Future<List<String>> _claves(WidgetTester tester) async =>
    (await enApp(tester, () => RegistroUsoService().eventos(DateTime(2000), DateTime(2100))))
        .map((e) => e.clave)
        .toList();

void main() {
  setUp(prepararPantallas);
  tearDown(limpiarPantallas);

  pantalla('Armar mi frase: verbo, categoría y pictograma, y otra frase (US603)', (tester) async {
    await conRegistro(tester);
    await activarVoz(tester);
    await abrir(tester, const ComunicacionPage());
    await tocar(tester, find.text('Armar mi frase'));
    await tocar(tester, find.text('Quiero'));
    await tocarSiHay(tester, find.text('Continuar'));
    await tocar(tester, find.text('Comer'));
    await tocar(tester, find.text('Continuar'));
    await tocar(tester, find.text('Pan'));
    await tocar(tester, find.text('Continuar'));
    expect(find.textContaining(RegExp('quiero', caseSensitive: false)), findsWidgets);
    expect(await _claves(tester), contains('frase'));
    await tocarSiHay(tester, find.text('Escuchar otra vez'));
    await tocarSiHay(tester, find.text('Armar otra frase'));
    await desactivarVoz(tester);
  });

  pantalla('Armar mi frase: «Me gusta», Borrar, retroceder y una categoría sin paso 3', (tester) async {
    await conRegistro(tester);
    await abrir(tester, const ComunicacionPage());
    await tocar(tester, find.text('Armar mi frase'));
    await tocar(tester, find.text('Me gusta'));
    await tocarSiHay(tester, find.text('Continuar'));
    await tocar(tester, find.text('Jugar'));
    await tocarSiHay(tester, find.text('Borrar'));
    await tocarSiHay(tester, find.text('Borrar'));
    await tocarSiHay(tester, porEtiqueta('Volver'));
    await tocarSiHay(tester, find.text('Necesito'));
    await tocarSiHay(tester, find.text('Continuar'));
    await tocar(tester, find.text('Baño'));
    await tocar(tester, find.text('Continuar'));
    expect(await _claves(tester), contains('frase'));
  });

  pantalla('Responder «No» y las subcategorías de Pedir algo (US601, US605)', (tester) async {
    await conRegistro(tester);
    await abrir(tester, const ComunicacionPage());
    await tocar(tester, find.text('Responder'));
    await tocar(tester, find.text('No'));
    expect(await _claves(tester), contains('no'));
    await tocarSiHay(tester, porEtiqueta('Volver'));
    await tocar(tester, find.text('Pedir algo'));
    for (final sub in ['Tomar', 'Jugar']) {
      await tocar(tester, find.text(sub));
      await tocarSiHay(tester, porEtiqueta('Volver'));
    }
    await tocarSiHay(tester, find.text('Baño'));
    expect(await _claves(tester), contains('com_bano'));
  });
}
