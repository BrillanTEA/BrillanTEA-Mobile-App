import 'package:brillantea/datos/base_datos.dart';
import 'package:brillantea/dominio/rutinas_app.dart';
import 'package:brillantea/dominio/rutinas_service.dart';
import 'package:brillantea/presentacion/area_padres/categoria_rutinas_config_page.dart';
import 'package:brillantea/presentacion/rutinas/rutinas_categorias_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/pantallas.dart';

// Rutinas activas de una categoría (US1005): activar o desactivar todas con confirmación,
// elegir una por una, salir sin guardar, filtros y búsqueda.

Future<void> _conRutinas(WidgetTester tester) async {
  await tester.runAsync(() async {
    final db = await BaseDatos().db;
    for (final r in rutinasApp) {
      await db.rawInsert('INSERT OR IGNORE INTO rutina (id, nombre) VALUES (?, ?)', [r.id, r.nombre]);
    }
  });
}

void main() {
  setUp(prepararPantallas);
  tearDown(limpiarPantallas);

  pantalla('«Desactivar todas» y «Activar todas» piden confirmación y se guardan', (tester) async {
    await conRegistro(tester);
    await _conRutinas(tester);
    await abrir(tester, const CategoriaRutinasConfigPage(categoria: 'Higiene'));
    await tocar(tester, porEtiqueta('Editar'));
    await tocar(tester, find.text('Desactivar todas'));
    await tocarSiHay(tester, porEtiqueta('Confirmar'));
    expect(find.text('¿Guardar los cambios?'), findsOneWidget);
    await tocar(tester, find.text('Sí, guardar'));
    final desactivadas = await enApp(tester, () => RutinasService().getRutinasDesactivadas());
    expect(desactivadas, isNotEmpty);

    await tocar(tester, porEtiqueta('Editar'));
    await tocar(tester, find.text('Activar todas'));
    await tocarSiHay(tester, porEtiqueta('Confirmar'));
    await tocarSiHay(tester, find.text('Sí, guardar'));
    expect(await enApp(tester, () => RutinasService().getRutinasDesactivadas()), isEmpty);
  });

  pantalla('elegir una por una y salir sin guardar', (tester) async {
    await conRegistro(tester);
    await _conRutinas(tester);
    await abrir(tester, const CategoriaRutinasConfigPage(categoria: 'Higiene'));
    await tocar(tester, porEtiqueta('Editar'));
    await tocar(tester, find.text('Elegir una por una'));
    expect(find.text('Editar Higiene'), findsOneWidget);
    await tocar(tester, find.byType(Switch));
    await tocar(tester, porEtiqueta('Cerrar'));
    expect(find.text('¿Salir sin guardar?'), findsOneWidget);
    await tocar(tester, find.text('Seguir editando'));
    await tocar(tester, porEtiqueta('Cerrar'));
    await tocar(tester, find.text('Salir sin guardar'));
    expect(find.text('Editar Higiene'), findsNothing);
    expect(await enApp(tester, () => RutinasService().getRutinasDesactivadas()), isEmpty);
  });

  pantalla('filtrar por estado y buscar sin resultados', (tester) async {
    await conRegistro(tester);
    await _conRutinas(tester);
    await abrir(tester, const CategoriaRutinasConfigPage(categoria: 'Higiene'));
    await tocar(tester, porEtiqueta('Filtrar'));
    await tocar(tester, find.text('Desactivadas'));
    expect(find.text('Filtrando: Desactivadas'), findsOneWidget);
    await tocarSiHay(tester, find.text('Restablecer filtros'));
    await tocar(tester, porEtiqueta('Filtrar'));
    await tocar(tester, find.text('Activas'));
    await tocarSiHay(tester, porEtiqueta('Cerrar'));
    await escribir(tester, 0, 'zzz');
    expect(find.text('No se encontraron rutinas con los filtros actuales.'), findsOneWidget);
    await tocarSiHay(tester, porEtiqueta('Quitar'));
  });

  pantalla('cada categoría muestra cuántas rutinas activas tiene (DEF-21)', (tester) async {
    await conRegistro(tester);
    await _conRutinas(tester);
    await abrir(tester, const RutinasCategoriasPage());
    await esperarHasta(tester, find.text('2 rutinas'));
    expect(find.text('2 rutinas'), findsOneWidget);

    final higiene = rutinasApp.firstWhere((r) => r.categoria == 'Higiene');
    await enApp(tester, () => RutinasService().setRutinaActiva(higiene.id, false));
    await esperarHastaQueNo(tester, find.text('2 rutinas'));
    expect(find.text('2 rutinas'), findsNothing);
    expect(find.text('1 rutina'), findsWidgets);
  });
}
