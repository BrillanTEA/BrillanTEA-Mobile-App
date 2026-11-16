import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_edge_ai/infraestructura/perfil_yolo26.dart';

void main() {
  test('el archivo y etiquetas pertenecen al candidato comprobado', () {
    expect(
        sha256.convert(File(PerfilYolo26.asset).readAsBytesSync()).toString(),
        PerfilYolo26.sha256Modelo);
    final labels = File(PerfilYolo26.asset.replaceAll('.tflite', '.txt'))
        .readAsLinesSync();
    PerfilYolo26.validarEtiquetas(labels);
    final contract = jsonDecode(
            File('assets/models/contrato_yolo26_35.json').readAsStringSync())
        as Map<String, dynamic>;
    expect((contract['clases'] as List).map((c) => c['clave']).toList(),
        PerfilYolo26.claves);
  });
  test('no acepta etiquetas COCO, faltantes ni IDs reordenados', () {
    expect(() => PerfilYolo26.validarEtiquetas(['person', 'dog']),
        throwsStateError);
    expect(
        () => PerfilYolo26.validarEtiquetas(
            PerfilYolo26.claves.reversed.toList()),
        throwsStateError);
    expect(
        () => PerfilYolo26.validarEtiquetas(
            [...PerfilYolo26.claves, 'jabon_liquido']),
        throwsStateError);
  });
  test('se rechaza la salida de la primera exportación errónea', () {
    PerfilYolo26.validarTensores(
        [1, 3, 640, 640], [1, 39, 8400], 'TensorType.float32');
    expect(
        () => PerfilYolo26.validarTensores(
            [1, 3, 640, 640], [1, 300, 6], 'float32'),
        throwsStateError);
    expect(
        () => PerfilYolo26.validarTensores(
            [1, 640, 640, 3], [1, 39, 8400], 'float32'),
        throwsStateError);
    expect(
        () => PerfilYolo26.validarTensores(
            [1, 3, 640, 640], [1, 39, 8400], 'uint8'),
        throwsStateError);
  });
  test('solo permite IDs del catálogo y puntuaciones finitas válidas', () {
    expect(PerfilYolo26.permite(0, .25), isTrue);
    expect(PerfilYolo26.permite(34, 1), isTrue);
    for (final id in [-1, 35, 79]) {
      expect(PerfilYolo26.permite(id, .9), isFalse);
    }
    for (final score in [double.nan, double.infinity, -.1, 1.1]) {
      expect(PerfilYolo26.permite(0, score), isFalse);
    }
  });
}
