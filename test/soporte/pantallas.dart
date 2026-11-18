import 'dart:io';

import 'package:brillantea/datos/base_datos.dart';
import 'package:brillantea/dominio/accesibilidad_service.dart';
import 'package:brillantea/dominio/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'entorno_prueba.dart';

// Ayudas para las pruebas de pantallas: abren una pantalla en un celular de 412 × 915 con la base
// SQLite de prueba, esperan las operaciones reales (base de datos, hash del PIN) y simulan los
// servicios de Android que la app usa fuera de su proceso (carpeta temporal y hoja de compartir).

const adultoPrueba = PerfilAdulto(
  nombres: 'María',
  apellidoPaterno: 'Gómez',
  apellidoMaterno: '',
  diaNacimiento: '12',
  mesNacimiento: 'Mayo',
  anioNacimiento: '1991',
  ciudadNacimiento: 'Barranco',
  edad: '35',
  sexo: 'Femenino',
  parentesco: 'Mamá',
);
const ninoPrueba = PerfilNino(nombre: 'Mateo', edad: 8, avatar: 'nino');
const ninaPrueba = PerfilNino(nombre: 'Lucía', edad: 7, avatar: 'nina');
const pinPrueba = '2580';

final entorno = EntornoPrueba();

/// Carpeta temporal que devuelve path_provider en las pruebas.
late Directory carpetaTemporal;

/// Archivos que la app mandó a la hoja de compartir.
final List<MethodCall> compartidos = [];

/// Prepara el entorno de cada prueba y simula los canales de Android.
Future<void> prepararPantallas() async {
  await entorno.preparar();
  carpetaTemporal = await Directory.systemTemp.createTemp('brillantea_tmp_');
  compartidos.clear();
  final mensajero = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  mensajero.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'),
      (llamada) async => carpetaTemporal.path);
  mensajero.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/share'),
      (llamada) async {
    compartidos.add(llamada);
    return 'dev.fluttercommunity.plus/share/unavailable';
  });
  mensajero.setMockMethodCallHandler(const MethodChannel('pe.brillantea.app/lock_task'),
      (llamada) async => false);
}

Future<void> limpiarPantallas() async {
  // Con límite de tiempo: una base ocupada no debe detener toda la ejecución.
  await entorno.limpiar().timeout(const Duration(seconds: 10), onTimeout: () {});
  if (await carpetaTemporal.exists()) await carpetaTemporal.delete(recursive: true);
}

/// Deja avanzar el tiempo simulado y las operaciones reales (base de datos, isolates).
Future<void> esperar(WidgetTester tester, {int vueltas = 3}) async {
  for (var i = 0; i < vueltas; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Espera corta para la exploración: deja terminar las operaciones rápidas de la base de datos.
Future<void> _esperarToque(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 250));
}

/// Espera hasta que aparezca [buscado] (por ejemplo, después de calcular el hash del PIN).
Future<void> esperarHasta(WidgetTester tester, Finder buscado, {int maxVueltas = 60}) async {
  for (var i = 0; i < maxVueltas && buscado.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Ejecuta una operación de la app dentro del reloj simulado de la prueba y la deja terminar.
/// Se usa en lugar de runAsync después de interactuar con la pantalla: si la pantalla dejó una
/// operación de la base de datos a medias, runAsync esperaría para siempre a que termine.
Future<T> enApp<T>(WidgetTester tester, Future<T> Function() operacion, {int maxVueltas = 150}) async {
  late T resultado;
  Object? error;
  var listo = false;
  operacion().then((valor) {
    resultado = valor;
    listo = true;
  }, onError: (Object e) {
    error = e;
    listo = true;
  });
  for (var i = 0; i < maxVueltas && !listo; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  if (error != null) throw error!;
  if (!listo) throw StateError('La operación de la app no terminó');
  return resultado;
}

/// Espera hasta que desaparezca [buscado].
Future<void> esperarHastaQueNo(WidgetTester tester, Finder buscado, {int maxVueltas = 60}) async {
  for (var i = 0; i < maxVueltas && buscado.evaluate().isNotEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> abrir(WidgetTester tester, Widget pagina, {List<NavigatorObserver> observadores = const []}) async {
  await tester.binding.setSurfaceSize(const Size(412, 915));
  await tester.runAsync(() async {
    await tester.pumpWidget(MaterialApp(home: pagina, navigatorObservers: observadores));
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await esperar(tester);
}

Future<void> tocar(WidgetTester tester, Finder destino) async {
  final elementos = destino.evaluate();
  final objeto = elementos.isEmpty ? null : elementos.first.renderObject;
  // Durante una transición el control puede no estar dibujado todavía: se toca sin desplazar.
  if (objeto != null && !objeto.debugNeedsLayout) {
    try {
      await tester.ensureVisible(destino.first);
    } catch (_) {
      // Se toca igual.
    }
  }
  await tester.pump();
  await tester.tap(destino.first, warnIfMissed: false);
  await esperar(tester);
}

/// Toca [destino] solo si está en la pantalla; devuelve si lo tocó.
Future<bool> tocarSiHay(WidgetTester tester, Finder destino) async {
  if (destino.evaluate().isEmpty) return false;
  await tocar(tester, destino);
  return true;
}

/// Cierra la pantalla o el diálogo de arriba.
Future<void> cerrarArriba(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await esperar(tester);
}

/// Escribe en el campo de texto número [indice] de la pantalla.
Future<void> escribir(WidgetTester tester, int indice, String texto) async {
  final campo = find.byType(TextField).at(indice);
  await tester.ensureVisible(campo);
  await tester.enterText(campo, texto);
  await esperar(tester, vueltas: 1);
}

Future<void> conPerfiles(WidgetTester tester, {PerfilNino nino = ninoPrueba}) async {
  await tester.runAsync(() async {
    await AuthService().actualizarPerfilAdulto(adultoPrueba);
    await AuthService().actualizarPerfilNino(nino);
    await AuthService().setAcuerdoPrivacidadAceptado(true);
  });
}

/// Registra el primer uso completo (perfiles y PIN), como al terminar la configuración inicial.
Future<void> conRegistro(WidgetTester tester, {PerfilNino nino = ninoPrueba}) async {
  await tester.runAsync(() async {
    await AuthService().registrarPrimerUso(adulto: adultoPrueba, pin: pinPrueba, nino: nino);
    await AuthService().setAcuerdoPrivacidadAceptado(true);
  });
}

Future<void> activarVoz(WidgetTester tester) async {
  await tester.runAsync(() async {
    await AccesibilidadService().setLeerVozAlta(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  entorno.voz.clear();
}

Future<void> desactivarVoz(WidgetTester tester) async {
  await tester.runAsync(() => AccesibilidadService().setLeerVozAlta(false));
}

/// Prueba de una pantalla: ignora solo los desbordes de diseño (la fuente de pruebas dibuja cada
/// letra como un cuadrado) y cierra la pantalla al final para cancelar sus temporizadores.
void pantalla(String descripcion, Future<void> Function(WidgetTester tester) cuerpo,
    {Timeout? timeout}) {
  testWidgets(descripcion, (tester) async {
    final previo = FlutterError.onError;
    FlutterError.onError = (detalle) {
      if (detalle.exceptionAsString().contains('overflowed')) return;
      previo?.call(detalle);
    };
    try {
      await cuerpo(tester);
    } finally {
      // Aunque la prueba falle, se deja terminar lo que la pantalla dejó a medias (por ejemplo,
      // guardar en la base de datos), se cierra la pantalla y se borra la base dentro del reloj de
      // la prueba. Si no, la base queda ocupada y las pruebas siguientes se quedan esperando.
      try {
        await esperar(tester);
        await tester.pumpWidget(const SizedBox.shrink());
        await esperar(tester);
        await tester.pump(const Duration(seconds: 2));
        await enApp(tester, () => BaseDatos().borrarTodo(), maxVueltas: 100);
      } catch (_) {
        // La falla original de la prueba es la que se informa.
      }
      FlutterError.onError = previo;
      await tester.binding.setSurfaceSize(null);
    }
  }, timeout: timeout ?? const Timeout(Duration(seconds: 90)));
}

/// Cuenta las rutas abiertas, para volver a la pantalla de partida después de cada toque.
class ContadorRutas extends NavigatorObserver {
  int rutas = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    rutas++;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    rutas--;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    rutas--;
  }
}

bool _esTocable(Widget w) =>
    (w is InkWell && (w.onTap != null || w.onLongPress != null)) ||
    (w is GestureDetector && w.onTap != null) ||
    (w is Switch && w.onChanged != null) ||
    (w is Checkbox && w.onChanged != null) ||
    (w is Slider && w.onChanged != null);

/// Prueba exploratoria automatizada: toca uno por uno los controles de la pantalla actual y,
/// hasta [profundidad] niveles, los de las pantallas y diálogos que se abren; después de cada
/// toque vuelve a la pantalla de partida. Antes de tocar, escribe en los campos de texto.
/// No toca los controles cuyo texto coincide con [evitar] (por ejemplo, la Cámara, que necesita
/// el hardware del celular). Devuelve cuántos toques hizo.
Future<int> explorar(
  WidgetTester tester,
  ContadorRutas pila, {
  int profundidad = 2,
  int maxPorPantalla = 20,
  RegExp? evitar,
  Future<void> Function()? reabrir,
}) async {
  var toques = 0;
  final inicio = pila.rutas;
  final campos = find.byType(TextField);
  for (var c = 0; c < campos.evaluate().length && c < 6; c++) {
    final campo = tester.widget<TextField>(campos.at(c));
    final numerico = campo.keyboardType == TextInputType.number ||
        campo.keyboardType == TextInputType.phone;
    try {
      await tester.enterText(campos.at(c), numerico ? pinPrueba : 'Ana');
      await _esperarToque(tester);
    } catch (_) {}
  }
  for (var i = 0; i < maxPorPantalla; i++) {
    final tocables = find.byWidgetPredicate(_esTocable);
    final total = tocables.evaluate().length;
    if (i >= total) break;
    final destino = tocables.at(i);
    if (evitar != null &&
        find.descendant(of: destino, matching: find.textContaining(evitar)).evaluate().isNotEmpty) {
      continue;
    }
    try {
      await tester.ensureVisible(destino);
      await tester.pump();
      await tester.tap(destino, warnIfMissed: false);
      toques++;
      await _esperarToque(tester);
    } catch (_) {
      continue;
    }
    if (pila.rutas > inicio && profundidad > 1) {
      toques += await explorar(tester, pila,
          profundidad: profundidad - 1, maxPorPantalla: 6, evitar: evitar);
    }
    var guardia = 0;
    while (pila.rutas > inicio && guardia++ < 6) {
      final navegadores = find.byType(Navigator);
      if (navegadores.evaluate().isEmpty) break;
      tester.state<NavigatorState>(navegadores.first).pop();
      await _esperarToque(tester);
    }
    // Si el control cerró la pantalla (por ejemplo, «Volver»), se abre otra vez y se sigue.
    if (pila.rutas < inicio && reabrir != null) {
      try {
        await reabrir();
      } catch (_) {
        break;
      }
    }
  }
  return toques;
}

/// Abre [pagina] encima de una pantalla vacía, para las pantallas que se cierran solas al terminar.
Future<void> abrirEncima(WidgetTester tester, Widget pagina) async {
  await abrir(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pagina)),
            child: const Text('Abrir pantalla'),
          ),
        ),
      ),
    ),
  );
  await tocar(tester, find.text('Abrir pantalla'));
}

/// Control con la etiqueta de accesibilidad [etiqueta] (por ejemplo, «Volver»).
Finder porEtiqueta(String etiqueta) =>
    find.byWidgetPredicate((w) => w is Semantics && w.properties.label == etiqueta);
