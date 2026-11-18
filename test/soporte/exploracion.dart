import 'package:brillantea/datos/base_datos.dart';
import 'package:brillantea/dominio/favoritos_service.dart';
import 'package:brillantea/dominio/registro_uso_service.dart';
import 'package:brillantea/dominio/rutinas_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pantallas.dart';

// Pruebas exploratorias automatizadas (monkey testing dirigido): en cada pantalla se escribe en los
// campos de texto y se toca, uno por uno, cada control; en las pantallas y diálogos que se abren se
// repite lo mismo un nivel más. La prueba falla si alguna pantalla lanza un error (los desbordes de
// diseño de la fuente de pruebas se ignoran). La Cámara se excluye porque necesita el hardware.

final _camara = RegExp(r'^Cámara$');

/// Datos de uso para que Seguimiento, Favoritos y Premios muestren contenido.
Future<void> conDatosDeUso(WidgetTester tester) async {
  await tester.runAsync(() async {
    final db = await BaseDatos().db;
    for (final r in rutinasApp) {
      await db.rawInsert('INSERT OR IGNORE INTO rutina (id, nombre) VALUES (?, ?)', [r.id, r.nombre]);
    }
    final registro = RegistroUsoService();
    await registro.registrar(RegistroUsoService.rutinaInicio, '1', etiqueta: 'Lavado de manos');
    await registro.registrar(RegistroUsoService.rutinaFin, '1', etiqueta: 'Lavado de manos');
    await registro.registrar(RegistroUsoService.peticion, 'agua', etiqueta: 'Quiero agua');
    await registro.registrar(RegistroUsoService.emocion, 'triste', etiqueta: 'Triste');
    await registro.registrar(RegistroUsoService.calma, 'respirar', etiqueta: 'Respirar');
    await registro.agregarNota('Hoy estuvo tranquilo.');
    await FavoritosService().init();
    await FavoritosService().toggleFavorito(FavoritoItem(
      id: 'vocab_animales_perro',
      nombre: 'PERRO',
      modulo: 'Vocabulario',
      colorModuloValue: 0xFF3D6D7E,
      assetPath: 'assets/images/vocab_perro.png',
      fraseVoz: 'Perro',
    ));
  });
}

void explorarPantalla(String nombre, Widget Function() pagina,
    {bool registrado = true, bool conDatos = false, bool conVoz = false, int profundidad = 1}) {
  pantalla('exploración: $nombre', (tester) async {
    if (registrado) await conRegistro(tester);
    if (conDatos) await conDatosDeUso(tester);
    if (conVoz) await activarVoz(tester);
    final pila = ContadorRutas();
    await abrir(tester, _Base(pagina), observadores: [pila]);
    pila.rutas = 1;
    Future<void> reabrir() => tocar(tester, find.text('Abrir pantalla'));
    await reabrir();
    final reloj = Stopwatch()..start();
    final toques =
        await explorar(tester, pila, profundidad: profundidad, evitar: _camara, reabrir: reabrir);
    debugPrint('Exploración de $nombre: $toques toques en ${reloj.elapsed.inSeconds} s');
    expect(toques, greaterThan(0));
    if (conVoz) await desactivarVoz(tester);
  }, timeout: const Timeout(Duration(minutes: 3)));
}

/// Pantalla base: la pantalla explorada se abre encima, así sus botones «Volver» tienen a dónde volver.
class _Base extends StatelessWidget {
  const _Base(this.pagina);

  final Widget Function() pagina;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pagina())),
            child: const Text('Abrir pantalla'),
          ),
        ),
      );
}


/// Prepara y limpia el entorno de un archivo de pruebas exploratorias.
void prepararExploracion() {
  setUp(() async {
    await prepararPantallas();
    FavoritosService().limpiarMemoria();
  });
  tearDown(limpiarPantallas);
}
