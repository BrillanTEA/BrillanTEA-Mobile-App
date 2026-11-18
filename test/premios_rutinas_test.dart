import 'package:brillantea/datos/base_datos.dart';
import 'package:brillantea/dominio/premios_service.dart';
import 'package:brillantea/dominio/rutinas_app.dart';
import 'package:brillantea/dominio/rutinas_data.dart';
import 'package:brillantea/dominio/rutinas_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/entorno_prueba.dart';

String _clave(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Las rutinas 1 a 5 vienen del catálogo; si el catálogo no se cargó, se crean para que
/// las claves foráneas de progreso_rutina y configuracion_rutina se cumplan.
Future<void> _asegurarRutinas() async {
  final db = await BaseDatos().db;
  for (var id = 1; id <= 5; id++) {
    await db.rawInsert('INSERT OR IGNORE INTO rutina (id, nombre) VALUES (?, ?)', [id, 'Rutina $id']);
  }
}

Future<void> _progreso(int rutina, DateTime dia, {bool completada = true}) async {
  await (await BaseDatos().db).insert('progreso_rutina', {
    'rutina_id': rutina,
    'fecha': _clave(dia),
    'paso_actual': 4,
    'completada': completada ? 1 : 0,
  });
}

void main() {
  final entorno = EntornoPrueba();
  setUp(() => entorno.preparar());
  tearDown(() => entorno.limpiar());

  group('Premios (US1401, US1402, US1403)', () {
    test('sin configuración guardada: premios activos, período semanal y meta 20', () async {
      final config = await PremiosService().config();
      expect(config.activados, isTrue);
      expect(config.periodo, PeriodoPremios.semanal);
      expect(config.meta, 20);
    });

    test('guarda el período y lleva la meta al rango de ese período', () async {
      final premios = PremiosService();
      var avisos = 0;
      void escuchar() => avisos++;
      premios.addListener(escuchar);

      await premios.guardar(activados: false, periodo: PeriodoPremios.diaria, meta: 3);
      var config = await premios.config();
      expect(config.activados, isFalse);
      expect(config.periodo, PeriodoPremios.diaria);
      expect(config.meta, 3);

      await premios.guardar(activados: true, periodo: PeriodoPremios.mensual, meta: 500);
      config = await premios.config();
      expect(config.periodo, PeriodoPremios.mensual);
      expect(config.meta, 100);

      premios.removeListener(escuchar);
      expect(avisos, 2);
    });

    test('una meta antigua fuera de rango o un período desconocido se corrigen al leer', () async {
      await (await BaseDatos().db)
          .update('configuracion_premios', {'periodo': 'anual', 'meta_semanal': 3}, where: 'id = 1');
      final config = await PremiosService().config();
      expect(config.periodo, PeriodoPremios.semanal);
      expect(config.meta, 10);
    });

    test('cuenta una medalla por rutina terminada dentro del período', () async {
      await _asegurarRutinas();
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      final lunes = PremiosService.inicioDelPeriodo(PeriodoPremios.semanal, ahora);
      final inicioMes = PremiosService.inicioDelPeriodo(PeriodoPremios.mensual, ahora);

      await _progreso(1, hoy);
      await _progreso(2, hoy);
      await _progreso(3, hoy, completada: false); // empezada, no terminada
      await _progreso(4, hoy.subtract(const Duration(days: 40))); // fuera de todos los períodos
      var semana = 2;
      var mes = 2;
      if (lunes != hoy) {
        await _progreso(5, lunes);
        semana++;
        if (!lunes.isBefore(inicioMes)) mes++;
      }

      final premios = PremiosService();
      expect(await premios.medallasDelPeriodo(PeriodoPremios.diaria), 2);
      expect(await premios.medallasDelPeriodo(PeriodoPremios.semanal), semana);
      expect(await premios.medallasDelPeriodo(PeriodoPremios.mensual), mes);
    });

    test('textos y mensajes de cada período', () {
      expect(PeriodoPremios.diaria.nombre, 'Diaria');
      expect(PeriodoPremios.mensual.adjetivo, 'mensual');
      expect(PeriodoPremios.semanal.unidad, 'por semana');
      expect(PeriodoPremios.diaria.cuando, 'hoy');
      expect(PeriodoPremios.mensual.tituloMeta, 'Meta del mes');
      expect(PremiosService.errorMeta(PeriodoPremios.diaria, null), isNull);
      expect(PremiosService.errorMeta(PeriodoPremios.diaria, 4), isNull);
      expect(PremiosService.errorMeta(PeriodoPremios.mensual, 10),
          'Mínimo 20 medallas por mes. Escribe un número de 20 a 100.');
      expect(PremiosService.lunesDeEstaSemana(DateTime(2026, 11, 19)), DateTime(2026, 11, 16));
      expect(const ConfigPremios().meta, 20);
    });
  });

  group('Rutinas: avance y configuración (US501, US506, US1005)', () {
    test('guarda el avance del día y lo marca como terminado', () async {
      await _asegurarRutinas();
      final rutinas = RutinasService();
      expect(await rutinas.getProgresoHoy(), isEmpty);
      expect((await rutinas.getProgresoRutina(1)).pasoActual, 0);

      await rutinas.guardarProgreso(rutinaId: 1, pasoActual: 2, completada: false);
      var progreso = await rutinas.getProgresoRutina(1);
      expect(progreso.pasoActual, 2);
      expect(progreso.completada, isFalse);

      await rutinas.marcarCompletada(rutinaId: 1, totalPasos: 4);
      progreso = await rutinas.getProgresoRutina(1);
      expect(progreso.pasoActual, 4);
      expect(progreso.completada, isTrue);
      expect((await rutinas.getProgresoHoy()).keys.toList(), [1]);
    });

    test('activa y desactiva rutinas sueltas y por categoría', () async {
      await _asegurarRutinas();
      final rutinas = RutinasService();
      expect(await rutinas.isRutinaActiva(1), isTrue);

      await rutinas.setRutinaActiva(1, false);
      expect(await rutinas.isRutinaActiva(1), isFalse);

      await rutinas.setCategoriaActiva(categoria: 'Higiene', activa: false, rutinaIdsDeCategoria: [1, 2]);
      expect(await rutinas.getRutinasDesactivadas(), {1, 2});

      await rutinas.setRutinasActivas({1: true, 2: true, 5: false});
      expect(await rutinas.getRutinasDesactivadas(), {5});
    });

    test('«Ir a rutina» solo ofrece rutinas activas que empiezan con el objeto (US405)', () async {
      await _asegurarRutinas();
      const cano = 'assets/pictogramas/cano_2414.png';
      expect((await rutinasQueEmpiezanCon(cano)).map((r) => r.nombre).toList(), ['Lavado de manos']);

      await RutinasService().setRutinaActiva(1, false);
      expect(await rutinasQueEmpiezanCon(cano), isEmpty);
      expect(await rutinasQueEmpiezanCon('assets/pictogramas/no_existe.png'), isEmpty);
    });

    test('el avance del día pasa a JSON y vuelve', () {
      const progreso = RutinaProgresoDia(pasoActual: 3, completada: true);
      final copia = RutinaProgresoDia.fromJson(progreso.toJson());
      expect(copia.pasoActual, 3);
      expect(copia.completada, isTrue);
      expect(RutinaProgresoDia.fromJson(const {}).pasoActual, 0);
    });

    test('el catálogo de rutinas agrupa cada rutina en su categoría', () {
      expect(RutinasCatalogo.porId(1)?.nombre, 'Lavado de manos');
      expect(RutinasCatalogo.porId(99), isNull);
      for (final categoria in RutinasCatalogo.categorias) {
        expect(RutinasCatalogo.porCategoria(categoria.nombre).map((r) => r.id).toSet(),
            categoria.rutinaIds.toSet(),
            reason: categoria.nombre);
      }
    });
  });
}
