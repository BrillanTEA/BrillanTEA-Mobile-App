import 'package:brillantea/datos/base_datos.dart';
import 'package:brillantea/dominio/premios_service.dart';
import 'package:brillantea/dominio/rutinas_app.dart';
import 'package:brillantea/dominio/rutinas_service.dart';
import 'package:brillantea/presentacion/area_padres/login_pin_page.dart';
import 'package:brillantea/presentacion/inicio/inicio_page.dart';
import 'package:brillantea/presentacion/premios/premios_page.dart';
import 'package:brillantea/presentacion/registro/bienvenida_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/pantallas.dart';

// Inicio (módulos, barra inferior y menú) y Premios (meta, período, salir sin guardar y meta
// cumplida) (RF-19, US1401 a US1403).

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

  pantalla('Inicio abre cada módulo y vuelve (sin la Cámara)', (tester) async {
    await conRegistro(tester);
    await abrir(tester, const InicioPage());
    for (final modulo in ['Comunicación', 'Vocabulario', 'Rutinas', 'Emociones', 'Situaciones', 'Calma']) {
      await tocar(tester, find.text(modulo));
      expect(find.byType(InicioPage, skipOffstage: false), findsOneWidget, reason: modulo);
      await cerrarArriba(tester);
      expect(find.text('Elige lo que quieres hacer.'), findsOneWidget, reason: modulo);
    }
    await tocar(tester, find.text('Favoritos'));
    await tocar(tester, find.text('Inicio'));
  });

  pantalla('el menú de Inicio abre el área de padres y restablece la app', (tester) async {
    await conRegistro(tester);
    await abrir(tester, const InicioPage());
    await tocar(tester, porEtiqueta('Menú'));
    await tocar(tester, find.text('Área de padres (PIN)'));
    expect(find.byType(LoginPinPage), findsOneWidget);
    await cerrarArriba(tester);
    await tocar(tester, porEtiqueta('Menú'));
    await tocar(tester, find.text('Restablecer onboarding (QA)'));
    await tocar(tester, find.text('Cancelar'));
    await tocar(tester, porEtiqueta('Menú'));
    await tocar(tester, find.text('Restablecer onboarding (QA)'));
    await tocar(tester, find.text('Restablecer'));
    await esperarHasta(tester, find.byType(BienvenidaPage));
    expect(find.byType(BienvenidaPage), findsOneWidget);
  });

  pantalla('Premios: elegir el período, escribir la meta y guardarla', (tester) async {
    await conRegistro(tester);
    await abrirEncima(tester, const PremiosConfigPage());
    await tocar(tester, find.text('Mensual'));
    await escribir(tester, 0, '30');
    await tocar(tester, find.text('Guardar'));
    expect(find.text('¿Guardar esta meta?'), findsOneWidget);
    await tocar(tester, find.text('Sí, guardar'));
    await esperarHastaQueNo(tester, find.byType(PremiosConfigPage));
    final config = await enApp(tester, () => PremiosService().config());
    expect(config.periodo, PeriodoPremios.mensual);
    expect(config.meta, 30);
  });

  pantalla('Premios: salir con cambios pregunta antes y desactivar no pide meta', (tester) async {
    await conRegistro(tester);
    await abrirEncima(tester, const PremiosConfigPage());
    await tocar(tester, find.text('Diaria'));
    await tocar(tester, porEtiqueta('Volver'));
    expect(find.text('¿Salir sin guardar?'), findsOneWidget);
    await tocar(tester, find.text('Seguir editando'));
    await tocar(tester, porEtiqueta('Volver'));
    await tocar(tester, find.text('Salir sin guardar'));
    expect(find.byType(PremiosConfigPage), findsNothing);

    await tocar(tester, find.text('Abrir pantalla'));
    await tocar(tester, find.byType(Switch));
    await tocar(tester, find.text('Guardar'));
    await esperarHastaQueNo(tester, find.byType(PremiosConfigPage));
    expect((await enApp(tester, () => PremiosService().config())).activados, isFalse);
  });

  pantalla('Mis premios celebra cuando el niño llega a la meta del día', (tester) async {
    await conRegistro(tester);
    await _conRutinas(tester);
    await tester.runAsync(() async {
      await PremiosService().guardar(activados: true, periodo: PeriodoPremios.diaria, meta: 3);
      for (final r in rutinasApp) {
        await RutinasService().marcarCompletada(rutinaId: r.id, totalPasos: r.pasos.length);
      }
    });
    await activarVoz(tester);
    await abrir(tester, const MisPremiosPage());
    expect(find.text('¡Lo lograste!'), findsWidgets);
    await tocarSiHay(tester, find.text('Volver a mis rutinas'));
    await desactivarVoz(tester);
  });
}
