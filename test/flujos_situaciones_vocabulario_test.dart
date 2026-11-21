import 'package:brillantea/dominio/documentos_legales.dart';
import 'package:brillantea/dominio/favoritos_service.dart';
import 'package:brillantea/presentacion/area_padres/privacidad_datos_page.dart';
import 'package:brillantea/presentacion/comun/hoja_documento_legal.dart';
import 'package:brillantea/presentacion/comun/pin_input_cuadros.dart';
import 'package:brillantea/presentacion/situaciones/situaciones_page.dart';
import 'package:brillantea/presentacion/vocabulario/emociones_page.dart';
import 'package:brillantea/presentacion/vocabulario/favoritos_page.dart';
import 'package:brillantea/presentacion/vocabulario/vocabulario_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/pantallas.dart';

// Situaciones de principio a fin, cada categoría de Vocabulario, los documentos legales y la
// entrada de PIN por recuadros (RF-09, RF-14, US901).

void main() {
  setUp(prepararPantallas);
  tearDown(limpiarPantallas);

  pantalla('una situación se recorre hasta «¡Muy bien!», se lee otra vez y se elige otra', (tester) async {
    await conRegistro(tester);
    await activarVoz(tester);
    await abrir(tester, const SituacionesPage());
    await tocar(tester, find.text('Ir al doctor'));
    for (var paso = 0; paso < 15 && find.text('¡Muy bien!').evaluate().isEmpty; paso++) {
      if (!await tocarSiHay(tester, find.text('Siguiente'))) await tocarSiHay(tester, find.text('Terminar'));
    }
    expect(find.text('¡Muy bien!'), findsWidgets);
    await tocar(tester, find.text('Leer otra vez'));
    await tocarSiHay(tester, porEtiqueta('Volver'));
    await tocar(tester, find.text('Saludar'));
    for (var paso = 0; paso < 15 && find.text('¡Muy bien!').evaluate().isEmpty; paso++) {
      if (!await tocarSiHay(tester, find.text('Siguiente'))) await tocarSiHay(tester, find.text('Terminar'));
    }
    await tocarSiHay(tester, find.text('Otra situación'));
    expect(find.text('¿Qué quieres repasar?'), findsOneWidget);
    await desactivarVoz(tester);
  });

  pantalla('cada categoría de Vocabulario muestra y busca sus pictogramas', (tester) async {
    await conRegistro(tester);
    for (final categoria in ['Colores', 'Números', 'Letras', 'Frutas', 'Formas', 'Animales']) {
      final pila = ContadorRutas();
      await abrir(tester, const VocabularioPage(), observadores: [pila]);
      if (!await tocarSiHay(tester, find.text(categoria))) continue;
      if (find.byType(TextField).evaluate().isNotEmpty) {
        await escribir(tester, 0, 'a');
        await escribir(tester, 0, '');
      }
      await explorar(tester, pila, profundidad: 1, maxPorPantalla: 10);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  pantalla('los documentos legales se abren en una hoja y se cierran', (tester) async {
    await conRegistro(tester);
    await abrir(tester, const PrivacidadDatosPage());
    await tocar(tester, find.text('Términos y condiciones'));
    await tocar(tester, find.text('Entendido'));
    await tocar(tester, find.text('Política de privacidad'));
    await tocar(tester, porEtiqueta('Cerrar'));
    expect(find.text('Privacidad y datos'), findsWidgets);
  });

  pantalla('«Entendido» queda por encima de la barra de navegación del celular (DEF-22)', (tester) async {
    const barra = 48.0;
    tester.view.viewPadding = FakeViewPadding(bottom: barra * tester.view.devicePixelRatio);
    tester.view.padding = FakeViewPadding(bottom: barra * tester.view.devicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetPadding);
    await abrir(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => mostrarHojaDocumentoLegal(context, politicaDePrivacidad),
              child: const Text('Abrir hoja'),
            ),
          ),
        ),
      ),
    );
    await tocar(tester, find.text('Abrir hoja'));
    await esperarHasta(tester, find.byType(HojaDocumentoLegal));
    final boton = find.widgetWithText(ElevatedButton, 'Entendido');
    final debajo = tester.getBottomLeft(find.byType(HojaDocumentoLegal)).dy - tester.getBottomLeft(boton).dy;
    expect(debajo, greaterThanOrEqualTo(barra + 22));
    await tocar(tester, boton);
    expect(find.byType(HojaDocumentoLegal), findsNothing);
  });

  pantalla('Favoritos se reordena por uso al volver a la pestaña (DEF-19)', (tester) async {
    FavoritosService().limpiarMemoria();
    await conRegistro(tester);
    await enApp(tester, () async {
      final servicio = FavoritosService();
      await servicio.init();
      for (final nombre in ['Primero', 'Segundo']) {
        await servicio.toggleFavorito(FavoritoItem(
          id: 'fav_$nombre',
          nombre: nombre,
          modulo: 'Vocabulario',
          colorModuloValue: 0xFF3D6D7E,
          fraseVoz: nombre,
        ));
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    var visible = true;
    late StateSetter cambiar;
    await abrir(
      tester,
      StatefulBuilder(builder: (context, setState) {
        cambiar = setState;
        return FavoritosPage(visible: visible);
      }),
    );
    bool primeroAntes() {
      final a = tester.getTopLeft(find.text('Primero').first);
      final b = tester.getTopLeft(find.text('Segundo').first);
      return a.dy < b.dy || (a.dy == b.dy && a.dx < b.dx);
    }

    expect(primeroAntes(), isTrue);
    await enApp(tester, () async {
      await FavoritosService().registrarUso('fav_Segundo');
      await FavoritosService().registrarUso('fav_Segundo');
    });
    await esperar(tester);
    // Mientras está a la vista no se mueve bajo el dedo del niño.
    expect(primeroAntes(), isTrue);

    cambiar(() => visible = false);
    await esperar(tester);
    cambiar(() => visible = true);
    await esperar(tester);
    expect(primeroAntes(), isFalse);
    FavoritosService().limpiarMemoria();
  });

  pantalla('las emociones quedan centradas en su tarjeta y sin barra lateral (DEF-24)', (tester) async {
    await conRegistro(tester);
    await abrir(tester, const EmocionesPage());
    expect(find.byType(Scrollbar), findsNothing);
    for (final nombre in ['Alegre', 'Triste']) {
      final tarjeta = find.ancestor(of: find.text(nombre), matching: find.byType(AnimatedContainer)).first;
      final imagen = find.descendant(of: tarjeta, matching: find.byType(Image)).first;
      final centro = tester.getCenter(tarjeta).dx;
      expect((tester.getCenter(find.text(nombre)).dx - centro).abs(), lessThan(1));
      expect((tester.getCenter(imagen).dx - centro).abs(), lessThan(1));
    }
  });

  pantalla('tocar un recuadro del PIN borra desde ese dígito', (tester) async {
    final control = TextEditingController();
    final cambios = <String>[];
    await abrir(
      tester,
      Scaffold(body: Center(child: PinInputCuadros(controller: control, onChanged: cambios.add))),
    );
    await tester.enterText(find.byType(TextField), '123');
    await esperar(tester, vueltas: 1);
    await tester.tapAt(tester.getTopLeft(find.byType(PinInputCuadros)) + const Offset(20, 20));
    await esperar(tester, vueltas: 1);
    expect(control.text.length, lessThan(3));
    expect(cambios, isNotEmpty);
  });
}
