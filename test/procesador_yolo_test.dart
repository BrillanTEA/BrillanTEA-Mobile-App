import 'dart:typed_data';

import 'package:brillantea/infraestructura/detector_worker.dart';
import 'package:brillantea/infraestructura/procesador_yolo.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fotograma BGRA de [w] × [h] con todos los píxeles del mismo color.
Frame _bgra(int w, int h, {int r = 30, int g = 20, int b = 10, int rotacion = 0}) {
  final bytes = Uint8List(w * h * 4);
  for (var i = 0; i < w * h; i++) {
    bytes[i * 4] = b;
    bytes[i * 4 + 1] = g;
    bytes[i * 4 + 2] = r;
    bytes[i * 4 + 3] = 255;
  }
  return Frame(
      width: w, height: h, planes: [bytes], rowStrides: [w * 4], pixelStrides: [4], isBgra: true, rotation: rotacion);
}

/// Fotograma YUV420 de [w] × [h] gris medio (Y = 128, U = V = 128).
Frame _yuvGris(int w, int h, {int rotacion = 0}) => Frame(
      width: w,
      height: h,
      planes: [
        Uint8List(w * h)..fillRange(0, w * h, 128),
        Uint8List((w ~/ 2) * (h ~/ 2))..fillRange(0, (w ~/ 2) * (h ~/ 2), 128),
        Uint8List((w ~/ 2) * (h ~/ 2))..fillRange(0, (w ~/ 2) * (h ~/ 2), 128),
      ],
      rowStrides: [w, w ~/ 2, w ~/ 2],
      pixelStrides: [1, 1, 1],
      isBgra: false,
      rotation: rotacion,
    );

void main() {
  group('Preprocesamiento del fotograma (Algoritmo 1, líneas 1 a 3)', () {
    test('escala sin deformar, rellena con gris (letterbox) y normaliza a 0–1', () {
      final p = ProcesadorYolo(formaEntrada: [1, 4, 4, 3], formaSalida: [1, 6, 8]);
      expect(p.entradaFloat, isTrue);
      expect(p.entrada.length, 4 * 4 * 3 * 4);
      // Fotograma de 2 × 4: ocupa el centro y deja una columna gris a cada lado.
      p.preprocesar(_bgra(2, 4));
      final f = p.entrada.buffer.asFloat32List();
      expect(f[0], closeTo(114 / 255, 1e-6)); // píxel (0, 0): relleno
      expect(f[3], closeTo(30 / 255, 1e-6)); // píxel (1, 0): R
      expect(f[4], closeTo(20 / 255, 1e-6)); // G
      expect(f[5], closeTo(10 / 255, 1e-6)); // B
      expect(f[9], closeTo(114 / 255, 1e-6)); // píxel (3, 0): relleno
    });

    test('convierte YUV420 a RGB, gira el fotograma y cuantiza a int8 en formato NCHW', () {
      final p = ProcesadorYolo(
        formaEntrada: [1, 3, 4, 4],
        formaSalida: [1, 6, 8],
        tipoEntrada: TipoTensor.int8,
        escalaEntrada: 1 / 255,
        ceroEntrada: -128,
      );
      expect(p.entradaFloat, isFalse);
      expect(p.entrada.length, 3 * 4 * 4);
      // 4 × 2 girado 90°: queda de 2 × 4, igual que en la prueba anterior.
      p.preprocesar(_yuvGris(4, 2, rotacion: 90));
      final e = p.entrada;
      expect(e[0], (114 - 128) & 0xFF); // relleno gris cuantizado
      expect(e[1], 0); // gris medio (128) cuantizado: 128 / 255 ÷ (1 / 255) − 128
      expect(e[16 + 1], 0); // canal G (plano siguiente)
      expect(e[32 + 1], 0); // canal B
    });

    test('las rotaciones de 180° y 270° y la entrada uint8 también se procesan', () {
      final p = ProcesadorYolo(
          formaEntrada: [1, 4, 4, 3], formaSalida: [1, 6, 8], tipoEntrada: TipoTensor.uint8, escalaEntrada: 1 / 255);
      p.preprocesar(_bgra(4, 4, rotacion: 180));
      expect(p.entrada[0], 30);
      p.preprocesar(_bgra(4, 4, r: 200, rotacion: 270));
      expect(p.entrada[0], 200);
    });
  });

  group('Decodificación de la salida (Algoritmo 1, líneas 5 a 15)', () {
    test('formato [1, 4 + clases, N]: mejor clase, umbral y supresión de no máximos', () {
      const n = 8;
      final p = ProcesadorYolo(formaEntrada: [1, 4, 4, 3], formaSalida: [1, 6, n], numClases: 2, coordenadasNormalizadas: true);
      p.preprocesar(_bgra(4, 4)); // sin relleno: la caja queda igual
      final out = Float32List(6 * n);
      void propuesta(int i, double cx, double cy, double w, double h, double s0, double s1) {
        out[i] = cx;
        out[n + i] = cy;
        out[2 * n + i] = w;
        out[3 * n + i] = h;
        out[4 * n + i] = s0;
        out[5 * n + i] = s1;
      }

      propuesta(0, 0.5, 0.5, 0.2, 0.2, 0.9, 0.1);
      propuesta(1, 0.52, 0.5, 0.2, 0.2, 0.8, 0.05); // casi la misma caja y clase: se suprime
      propuesta(2, 0.2, 0.2, 0.1, 0.1, 0.1, 0.3); // otra clase
      propuesta(3, 0.8, 0.8, 0.1, 0.1, 0.1, 0.2); // bajo el umbral
      final dets = p.postprocesar(out, 0.25);
      expect(dets, hasLength(2));
      expect(dets.first.cls, 0);
      expect(dets.first.score, closeTo(0.9, 1e-6));
      expect(dets.first.left, closeTo(0.4, 1e-6));
      expect(dets.first.bottom, closeTo(0.6, 1e-6));
      expect(dets.last.cls, 1);
    });

    test('formato transpuesto [1, N, 4 + clases] con coordenadas en píxeles', () {
      const n = 8;
      const ch = 7; // 3 clases
      final p = ProcesadorYolo(formaEntrada: [1, 4, 4, 3], formaSalida: [1, n, ch], numClases: 3);
      p.preprocesar(_bgra(4, 4));
      final out = Float32List(n * ch);
      // cx, cy, w, h en píxeles de la entrada de 4 × 4 (un ancho mayor que 2 indica píxeles).
      out.setAll(0, [2, 2, 3, 3, 0.1, 0.7, 0.1]);
      final dets = p.postprocesar(out, 0.5);
      expect(dets, hasLength(1));
      expect(dets.single.cls, 1);
      expect(dets.single.left, closeTo(0.125, 1e-6));
      expect(dets.single.right, closeTo(0.875, 1e-6));
    });

    test('formato de extremo a extremo [1, N, 6] (sin supresión de no máximos)', () {
      final p = ProcesadorYolo(formaEntrada: [1, 4, 4, 3], formaSalida: [1, 3, 6], coordenadasNormalizadas: true);
      p.preprocesar(_bgra(4, 4));
      final out = Float32List.fromList([
        0.1, 0.1, 0.3, 0.3, 0.95, 4, //
        0.5, 0.5, 0.9, 0.9, 0.10, 2, // bajo el umbral
        0.6, 0.6, 0.8, 0.8, 0.60, 7,
      ]);
      final dets = p.postprocesar(out, 0.25);
      expect(dets.map((d) => d.cls).toList(), [4, 7]);
      expect(dets.first.right, closeTo(0.3, 1e-6));
    });

    test('descuantiza la salida float32, int8 y uint8', () {
      final f = ProcesadorYolo(formaEntrada: [1, 4, 4, 3], formaSalida: [1, 3, 6]);
      final valores = Float32List.fromList([0.5, -2]);
      expect(f.decuantizar(valores.buffer.asUint8List()), [0.5, -2]);
      final i8 = ProcesadorYolo(
          formaEntrada: [1, 4, 4, 3], formaSalida: [1, 3, 6], tipoSalida: TipoTensor.int8, escalaSalida: 0.5, ceroSalida: -1);
      expect(i8.decuantizar(Uint8List.fromList([2, 255])), [1.5, 0]);
      final u8 = ProcesadorYolo(
          formaEntrada: [1, 4, 4, 3], formaSalida: [1, 3, 6], tipoSalida: TipoTensor.uint8, escalaSalida: 0.25);
      expect(u8.decuantizar(Uint8List.fromList([8])), [2]);
    });
  });

  group('Supresión de no máximos e IoU (Fragmento 2)', () {
    test('IoU de cajas iguales, separadas, solapadas y sin área', () {
      final a = Detection(0, 0.9, 0, 0, 2, 2);
      expect(ProcesadorYolo.interseccionSobreUnion(a, Detection(0, 0.9, 0, 0, 2, 2)), 1);
      expect(ProcesadorYolo.interseccionSobreUnion(a, Detection(0, 0.9, 3, 3, 4, 4)), 0);
      expect(ProcesadorYolo.interseccionSobreUnion(a, Detection(0, 0.9, 1, 0, 3, 2)), closeTo(1 / 3, 1e-9));
      expect(ProcesadorYolo.interseccionSobreUnion(Detection(0, 1, 1, 1, 1, 1), Detection(0, 1, 1, 1, 1, 1)), 0);
    });

    test('conserva la más segura de cada grupo, no mezcla clases y respeta el máximo', () {
      final dets = [
        Detection(0, 0.6, 0, 0, 2, 2),
        Detection(0, 0.9, 0.1, 0, 2.1, 2),
        Detection(1, 0.7, 0, 0, 2, 2), // otra clase en el mismo lugar: se conserva
        Detection(0, 0.5, 5, 5, 6, 6),
      ];
      final quedan = ProcesadorYolo.supresionNoMaximos(dets, 0.45, 10);
      expect(quedan.map((d) => d.score).toList(), [0.9, 0.7, 0.5]);
      expect(ProcesadorYolo.supresionNoMaximos(List.of(dets), 0.45, 2), hasLength(2));
    });
  });
}
