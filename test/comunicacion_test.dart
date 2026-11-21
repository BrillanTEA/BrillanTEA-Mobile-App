import 'dart:io';

import 'package:brillantea/dominio/comunicacion_data.dart';
import 'package:flutter_test/flutter_test.dart';

VerboFrase _verbo(String clave) => verbosFrase.firstWhere((v) => v.clave == clave);
OpcionComunicacion _categoria(String id) => categoriasFrase.firstWhere((c) => c.id == id);
OpcionComunicacion _objeto(String categoria, String id) =>
    objetosFrase[categoria]!.firstWhere((o) => o.id == id);

void main() {
  group('Comunicación: Armar mi frase (US603, US604, RF-12)', () {
    test('arma las frases de ejemplo del diseño', () {
      expect(
          armarFrase(verbo: _verbo('quiero'), categoria: _categoria('tomar'), objeto: _objeto('tomar', 'agua')),
          'Yo quiero agua');
      expect(
          armarFrase(
              verbo: _verbo('megusta'), categoria: _categoria('jugar'), objeto: _objeto('jugar', 'peluches')),
          'A mí me gusta jugar con peluches');
      expect(
          armarFrase(verbo: _verbo('noquiero'), categoria: _categoria('comer'), objeto: _objeto('comer', 'pollo')),
          'Yo no quiero pollo');
      expect(armarFrase(verbo: _verbo('necesito'), categoria: _categoria('ayuda')), 'Yo necesito ayuda');
      expect(
          armarFrase(verbo: _verbo('quiero'), categoria: _categoria('duele'), objeto: _objeto('duele', 'cabeza')),
          'A mí me duele la cabeza');
    });

    test('Baño y Ayuda terminan en el paso 2; las demás categorías piden un pictograma', () {
      expect(categoriaTienePaso3('bano'), isFalse);
      expect(categoriaTienePaso3('ayuda'), isFalse);
      for (final c in ['comer', 'tomar', 'jugar', 'duele']) {
        expect(categoriaTienePaso3(c), isTrue, reason: c);
      }
    });

    test('las preguntas cambian según el verbo y la categoría', () {
      expect(preguntaPaso2('megusta'), '¿Qué te gusta?');
      expect(preguntaPaso2('noquiero'), '¿Qué no quieres?');
      expect(preguntaPaso2('necesito'), '¿Qué necesitas?');
      expect(preguntaPaso3('quiero', 'tomar'), '¿Qué quieres tomar?');
      expect(preguntaPaso3('megusta', 'jugar'), '¿Con qué te gusta jugar?');
      expect(preguntaPaso3('noquiero', 'comer'), '¿Qué no quieres comer?');
      expect(preguntaPaso3('quiero', 'duele'), '¿Dónde te duele?');
    });

    test('cada pictograma de Comunicación está empaquetado', () {
      final assets = <String>{
        for (final v in verbosFrase) v.asset,
        for (final c in categoriasFrase) c.asset,
        for (final lista in objetosFrase.values)
          for (final o in lista) o.asset,
        for (final p in [...pedidosComer, ...pedidosTomar, ...pedidosJugar]) p.asset,
      };
      expect(assets.where((a) => !File(a).existsSync()).toList(), isEmpty);
    });
  });
}
