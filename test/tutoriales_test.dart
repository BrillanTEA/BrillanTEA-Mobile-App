import 'dart:io';

import 'package:brillantea/presentacion/area_padres/tutoriales_contenido.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tutoriales de 7 pantallas por módulo (US1502)', () {
    test('los seis módulos con tutorial por pasos están completos', () {
      expect(guiasTutorial.keys.toSet(), {'camara', 'comunicacion', 'vocabulario', 'rutinas', 'emociones', 'calma'});
      for (final e in guiasTutorial.entries) {
        final g = e.value;
        expect(g.pasos.length, 5, reason: e.key);
        expect(g.consejos.length, 3, reason: e.key);
        expect(g.idea.trim(), isNotEmpty, reason: e.key);
        expect(g.paraQueSirve.trim(), isNotEmpty, reason: e.key);
        expect(g.comoAcompanar.trim(), isNotEmpty, reason: e.key);
        for (final p in g.pasos) {
          expect(p.titulo.trim(), isNotEmpty, reason: e.key);
          expect(p.texto.trim(), isNotEmpty, reason: e.key);
        }
      }
    });

    test('la captura de cada paso está empaquetada', () {
      final rutas = [
        for (final clave in guiasTutorial.keys)
          for (var n = 1; n <= 5; n++) GuiaTutorial.imagenPaso(clave, n),
      ];
      expect(rutas.length, 30);
      expect(rutas.where((r) => !File(r).existsSync()).toList(), isEmpty);
    });

    test('Situaciones conserva su tutorial de detalle', () {
      expect(guiasTutorial.containsKey('situaciones'), isFalse);
    });
  });
}
