// Pruebas automáticas de la asociación objeto → pictograma → frase → rutina (indicador OE3-I3).
// Correr desde la carpeta del proyecto:  flutter test test/catalogo_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:brillantea/dominio/premios_service.dart';
import 'package:brillantea/dominio/rutinas_app.dart';
import 'package:brillantea/dominio/rutinas_data.dart';

Map<String, dynamic> _catalogo() =>
    jsonDecode(File('assets/catalogo.json').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> _lista(String clave) =>
    (_catalogo()[clave] as List).cast<Map<String, dynamic>>();

void main() {
  group('Catálogo (OE2-I3: 5 rutinas, 35 objetos y 41 pictogramas)', () {
    test('hay 35 objetos con clave única', () {
      final objetos = _lista('objetos');
      expect(objetos.length, 35);
      final claves = objetos.map((o) => o['clave']).toSet();
      expect(claves.length, 35, reason: 'hay claves repetidas');
    });

    test('hay 5 rutinas', () {
      expect(_lista('rutinas').length, 5);
    });

    test('la carpeta de pictogramas tiene 41 archivos', () {
      final png = Directory('assets/pictogramas')
          .listSync()
          .whereType<File>()
          .where((f) =>
              f.path.toLowerCase().endsWith('.png') ||
              f.path.toLowerCase().endsWith('.webp'));
      expect(png.length, 41);
    });
  });

  group('Asociación objeto → pictograma → frase → rutina (OE3-I3)', () {
    final objetos = _lista('objetos');
    final rutinasIds = _lista('rutinas').map((r) => r['id']).toSet();

    for (final o in objetos) {
      final clave = o['clave'] as String;
      test('$clave tiene nombre, frase y pictograma existente', () {
        expect((o['nombre'] as String?)?.trim(), isNotEmpty,
            reason: '$clave sin nombre');
        expect((o['frase_apoyo'] as String?)?.trim(), isNotEmpty,
            reason: '$clave sin frase');
        final archivo = o['archivo_pictograma'] as String?;
        expect(archivo, isNotNull, reason: '$clave sin pictograma');
        expect(File('assets/pictogramas/$archivo').existsSync(), isTrue,
            reason: 'falta assets/pictogramas/$archivo ($clave)');
        final rutina = o['rutina_id'];
        if (rutina != null) {
          expect(rutinasIds.contains(rutina), isTrue,
              reason: '$clave apunta a la rutina $rutina, que no existe');
        }
      });
    }

    test('cada rutina del catálogo tiene su pictograma', () {
      for (final r in _lista('rutinas')) {
        expect(
            File('assets/pictogramas/${r['archivo_pictograma']}').existsSync(),
            isTrue,
            reason: 'falta el pictograma de la rutina ${r['nombre']}');
      }
    });
  });

  group('Modelo35 y catálogo', () {
    test('las 35 etiquetas siguen exactamente el orden de IDs del catálogo', () {
      final labels =
          File('assets/models/yolo26_35_020_fp32.txt').readAsLinesSync();
      expect(labels, _lista('objetos').map((o) => o['clave']).toList());
      expect(labels.length, 35);
    });
    test('cada objeto tiene una sola clase del modelo (id_modelo = su posición)', () {
      final objetos = _lista('objetos');
      for (var i = 0; i < objetos.length; i++) {
        final o = objetos[i];
        expect(o['id_modelo'], i, reason: '${o['clave']} con id_modelo incorrecto');
        for (final viejo in const ['coco_clase', 'clase_propia', 'requiere_finetuning', 'coco_estado']) {
          expect(o.containsKey(viejo), isFalse, reason: '${o['clave']} aún tiene $viejo');
        }
      }
    });
  });

  group('Rutinas de la app', () {
    test('son 5 y cada paso tiene nombre, frase y pictograma existente', () {
      expect(rutinasApp.length, 5);
      for (final r in rutinasApp) {
        expect(r.pasos, isNotEmpty, reason: '${r.nombre} no tiene pasos');
        for (final paso in r.pasos) {
          expect(paso.nombre.trim(), isNotEmpty);
          expect(paso.fraseVoz.trim(), isNotEmpty);
          expect(File(paso.archivoPictograma).existsSync(), isTrue,
              reason:
                  'falta ${paso.archivoPictograma} (${r.nombre}, paso ${paso.numero})');
          if (paso.segundos != null) {
            expect(paso.segundos! > 0, isTrue,
                reason: 'temporizador inválido en ${paso.nombre}');
          }
        }
      }
    });

    test('pasos, etiquetas y cierre como en el Figma', () {
      expect(rutinasApp.map((r) => r.pasos.length).toList(), [4, 5, 5, 6, 5]);
      for (final r in rutinasApp) {
        expect(r.mensajeFinal.trim(), isNotEmpty);
        expect(RutinasCatalogo.porId(r.id)?.totalPasos, r.pasos.length,
            reason: 'totalPasos de ${r.nombre} no coincide en rutinas_data.dart');
        for (final paso in r.pasos) {
          expect(paso.nombreCorto.trim(), isNotEmpty);
        }
      }
    });

    test('«Ir a la rutina» solo con el objeto del primer paso (Ir a comer, ninguno)', () {
      final objetos = _lista('objetos');
      for (final r in rutinasApp) {
        final primeros = objetos
            .where((o) => o['rutina_id'] == r.id && o['paso'] == 1)
            .map((o) => 'assets/pictogramas/${o['archivo_pictograma']}')
            .toList();
        if (r.assetObjetoInicio == null) {
          expect(primeros, isEmpty, reason: '${r.nombre} no debe tener objeto de inicio');
        } else {
          expect(File(r.assetObjetoInicio!).existsSync(), isTrue);
          expect(primeros, [r.assetObjetoInicio],
              reason: 'catalogo.json y rutinas_app.dart no coinciden en ${r.nombre}');
        }
      }
    });

    test('los pasos están numerados en orden', () {
      for (final r in rutinasApp) {
        for (var i = 0; i < r.pasos.length; i++) {
          expect(r.pasos[i].numero, i + 1,
              reason:
                  '${r.nombre}: el paso ${i + 1} tiene número ${r.pasos[i].numero}');
        }
      }
    });
  });

  group('Premios', () {
    test('la semana empieza el lunes', () {
      // miércoles 21/10/2026 → lunes 19/10/2026
      expect(PremiosService.lunesDeEstaSemana(DateTime(2026, 10, 21, 15)),
          DateTime(2026, 10, 19));
      // lunes → el mismo día
      expect(PremiosService.lunesDeEstaSemana(DateTime(2026, 10, 19, 8)),
          DateTime(2026, 10, 19));
      // domingo 25/10/2026 → lunes 19/10/2026
      expect(PremiosService.lunesDeEstaSemana(DateTime(2026, 10, 25, 22)),
          DateTime(2026, 10, 19));
    });

    test('las metas siguen los rangos del Figma y el valor por defecto es válido',
        () {
      for (final p in PeriodoPremios.values) {
        final r = p.rango;
        expect(r.minimo <= r.porDefecto && r.porDefecto <= r.maximo, isTrue);
      }
      expect(PeriodoPremios.diaria.rango.minimo, 15);
      expect(PeriodoPremios.diaria.rango.maximo, 25);
      expect(PeriodoPremios.semanal.rango.minimo, 30);
      expect(PeriodoPremios.semanal.rango.maximo, 100);
      expect(PeriodoPremios.mensual.rango.minimo, 50);
      expect(PeriodoPremios.mensual.rango.maximo, 100);
    });

    test('la meta fuera de rango da el mensaje del Figma', () {
      expect(PremiosService.errorMeta(PeriodoPremios.semanal, 30), isNull);
      expect(PremiosService.errorMeta(PeriodoPremios.semanal, null), isNull);
      expect(PremiosService.errorMeta(PeriodoPremios.semanal, 1000),
          'Máximo 100 medallas por semana. Escribe un número de 30 a 100.');
      expect(PremiosService.errorMeta(PeriodoPremios.semanal, 10),
          'Mínimo 30 medallas por semana. Escribe un número de 30 a 100.');
    });

    test('el período empieza hoy, el lunes o el día 1', () {
      final miercoles = DateTime(2026, 10, 21, 15);
      expect(PremiosService.inicioDelPeriodo(PeriodoPremios.diaria, miercoles),
          DateTime(2026, 10, 21));
      expect(PremiosService.inicioDelPeriodo(PeriodoPremios.semanal, miercoles),
          DateTime(2026, 10, 19));
      expect(PremiosService.inicioDelPeriodo(PeriodoPremios.mensual, miercoles),
          DateTime(2026, 10, 1));
    });
  });
}
