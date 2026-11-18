import 'package:brillantea/dominio/favoritos_service.dart';
import 'package:brillantea/dominio/registro_uso_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/entorno_prueba.dart';

FavoritoItem _favorito(String id) => FavoritoItem(
      id: id,
      nombre: 'Nombre $id',
      modulo: 'Vocabulario',
      colorModuloValue: 0xFF3D6D7E,
      fraseVoz: 'Frase $id',
    );

/// Separa las marcas de tiempo (en milisegundos) de dos registros seguidos.
Future<void> _pausa() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  final entorno = EntornoPrueba();
  setUp(() async {
    await entorno.preparar();
    FavoritosService().limpiarMemoria();
  });
  tearDown(() => entorno.limpiar());

  group('Favoritos (RF-10, US706)', () {
    test('agrega, ordena por uso con desempate por antigüedad y quita favoritos', () async {
      final favoritos = FavoritosService();
      await favoritos.init();
      expect(favoritos.isEmpty, isTrue);

      for (final id in ['a', 'b', 'c']) {
        await favoritos.toggleFavorito(_favorito(id));
        await _pausa();
      }
      expect(favoritos.esFavorito('b'), isTrue);
      expect(favoritos.favoritos.map((f) => f.id).toList(), ['a', 'b', 'c']);

      await favoritos.registrarUso('c');
      await favoritos.registrarUso('c');
      await favoritos.registrarUso('b');
      await favoritos.registrarUso('no_existe');
      expect(favoritos.favoritos.map((f) => f.id).toList(), ['c', 'b', 'a']);

      await favoritos.toggleFavorito(_favorito('b'));
      expect(favoritos.esFavorito('b'), isFalse);
      await favoritos.eliminarFavorito('a');
      expect(favoritos.favoritos.map((f) => f.id).toList(), ['c']);
    });

    test('al volver a abrir la app recupera los favoritos y su uso desde SQLite', () async {
      final favoritos = FavoritosService();
      await favoritos.init();
      await favoritos.toggleFavorito(_favorito('a'));
      await _pausa();
      await favoritos.toggleFavorito(_favorito('b'));
      await favoritos.registrarUso('b');

      favoritos.limpiarMemoria();
      expect(favoritos.isEmpty, isTrue);
      await favoritos.init();
      expect(favoritos.favoritos.map((f) => f.id).toList(), ['b', 'a']);
      expect(favoritos.favoritos.first.contadorUso, 1);
    });

    test('un favorito pasa a JSON y a fila sin perder datos', () {
      final item = FavoritoItem(
        id: 'perro',
        nombre: 'Perro',
        modulo: 'Vocabulario',
        colorModuloValue: 0xFF112233,
        assetPath: 'assets/images/vocab_perro.png',
        simboloTexto: 'P',
        silabas: 'PE · RRO',
        fraseVoz: 'Perro',
        contadorUso: 2,
      );
      final desdeJson = FavoritoItem.fromJson(item.toJson());
      expect(desdeJson.silabas, 'PE · RRO');
      expect(desdeJson.contadorUso, 2);
      expect(desdeJson.colorModulo, const Color(0xFF112233));
      final desdeFila = FavoritoItem.fromFila(item.toFila(1));
      expect(desdeFila.assetPath, 'assets/images/vocab_perro.png');
      expect(desdeFila.simboloTexto, 'P');
      expect(desdeFila.fraseVoz, 'Perro');
    });
  });

  group('Registro de uso y seguimiento (RF-15, US1008)', () {
    test('guarda los eventos con su fecha y los filtra por período', () async {
      final registro = RegistroUsoService();
      final antes = DateTime.now().subtract(const Duration(seconds: 1));
      await registro.registrar(RegistroUsoService.peticion, 'com_comer', etiqueta: 'Quiero comer');
      await _pausa();
      await registro.registrar(RegistroUsoService.emocion, 'triste');
      final despues = DateTime.now().add(const Duration(seconds: 1));

      final eventos = await registro.eventos(antes, despues);
      expect(eventos.map((e) => e.tipo).toList(), ['peticion', 'emocion']);
      expect(eventos.first.etiqueta, 'Quiero comer');
      expect(eventos.last.etiqueta, 'triste');
      expect(await registro.eventos(despues, despues.add(const Duration(days: 1))), isEmpty);
    });

    test('guarda las notas para el especialista, de la más reciente a la más antigua', () async {
      final registro = RegistroUsoService();
      await registro.agregarNota('Primera nota');
      await _pausa();
      await registro.agregarNota('Segunda nota');
      expect((await registro.notas()).map((n) => n.texto).toList(), ['Segunda nota', 'Primera nota']);
      expect(await registro.notas(limite: 1), hasLength(1));
    });

    test('el resumen cuenta rutinas, peticiones, emociones y lo más usado', () {
      final dia = DateTime(2026, 11, 16, 10);
      final eventos = [
        EventoUso(RegistroUsoService.rutinaInicio, '1', 'Lavado de manos', dia),
        EventoUso(RegistroUsoService.rutinaPaso, '1', 'Lavado de manos', dia),
        EventoUso(RegistroUsoService.rutinaFin, '1', 'Lavado de manos', dia),
        EventoUso(RegistroUsoService.rutinaFin, '1', 'Lavado de manos', dia), // mismo día: no suma
        EventoUso(RegistroUsoService.rutinaInicio, '2', 'Cepillado de dientes', dia),
        EventoUso(RegistroUsoService.peticion, 'agua', 'Quiero agua', dia),
        EventoUso(RegistroUsoService.peticion, 'agua', 'Quiero agua', dia),
        EventoUso(RegistroUsoService.respuesta, 'si', 'Sí', dia),
        EventoUso(RegistroUsoService.pictograma, 'perro', 'Perro', dia),
        EventoUso(RegistroUsoService.emocion, 'triste', 'Triste', dia),
        EventoUso(RegistroUsoService.emocion, 'triste', 'Triste', dia),
        EventoUso(RegistroUsoService.emocion, 'alegre', 'Alegre', dia),
        EventoUso(RegistroUsoService.objeto, 'cano', 'Caño', dia),
        EventoUso(RegistroUsoService.calma, 'respirar', 'Respirar', dia),
      ];
      final resumen = ResumenSeguimiento.desde(eventos, dia, dia.add(const Duration(days: 1)));
      expect(resumen.rutinasIniciadas, 2);
      expect(resumen.rutinasCompletadas, 1);
      expect(resumen.completadasPorRutina, {'Lavado de manos': 1});
      expect(resumen.peticiones, 2);
      expect(resumen.respuestas, 1);
      expect(resumen.emociones, {'Triste': 2, 'Alegre': 1});
      expect(resumen.emocionFrecuente, 'Triste');
      expect(resumen.emocionFrecuenteVeces, 2);
      expect(resumen.momentosDificiles, 2);
      expect(resumen.masUsados.first.key, 'Quiero agua');
      expect(resumen.masUsados.first.value, 2);
      expect(resumen.objetosTocados, 1);
      expect(resumen.vacio, isFalse);
      expect(ResumenSeguimiento.desde(const [], dia, dia).vacio, isTrue);
    });

    test('la semana actual incluye lo de hoy y la semana anterior queda vacía', () async {
      await RegistroUsoService().registrar(RegistroUsoService.peticion, 'agua', etiqueta: 'Quiero agua');
      final (actual, anterior) = await ResumenSeguimiento.semanaActualYAnterior();
      expect(actual.peticiones, 1);
      expect(anterior.vacio, isTrue);
    });
  });
}
