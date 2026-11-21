import 'dart:io';

import 'package:brillantea/presentacion/vocabulario/emociones_page.dart';
import 'package:brillantea/presentacion/vocabulario/vocabulario_catalogo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Vocabulario (US701, US702)', () {
    test('las seis categorías tienen los elementos del diseño', () {
      final cantidad = {for (final c in categoriasVocabulario) c.id: c.elementos.length};
      expect(cantidad, {
        'animales': 25,
        'colores': 8,
        'numeros': 100,
        'letras': 27,
        'frutas': 15,
        'formas': 11,
      });
    });

    test('los id no se repiten, para no mezclar favoritos', () {
      final ids = [for (final c in categoriasVocabulario) ...c.elementos.map((e) => e.id)];
      expect(ids.toSet().length, ids.length);
    });

    test('cada imagen del vocabulario está empaquetada', () {
      final rutas = <String>{
        for (final c in categoriasVocabulario) c.assetBadge,
        for (final c in categoriasVocabulario)
          for (final e in c.elementos)
            if (e.assetPath != null) e.assetPath!,
      };
      expect(rutas.where((r) => !File(r).existsSync()).toList(), isEmpty);
    });
  });

  group('Emociones (US703, US704)', () {
    test('hay 8 emociones con su imagen', () {
      final emociones = EmocionesPage.emociones;
      expect(emociones.map((e) => e.id).toList(),
          ['alegre', 'triste', 'enojado', 'asustado', 'nervioso', 'cansado', 'sorprendido', 'aburrido']);
      for (final e in emociones) {
        expect(File(e.assetPath).existsSync(), isTrue, reason: e.assetPath);
      }
    });

    test('todas, menos Alegre, tienen la respuesta para el niño y para la niña', () {
      for (final e in EmocionesPage.emociones) {
        if (e.id == 'alegre') continue;
        expect(e.respuestaMasculina.trim(), isNotEmpty, reason: e.id);
        expect(e.respuestaFemenina.trim(), isNotEmpty, reason: e.id);
      }
    });
  });
}
