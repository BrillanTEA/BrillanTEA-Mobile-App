import 'dart:math';
import 'dart:typed_data';

import 'detector_worker.dart';

/// Tipo de dato de un tensor del modelo.
enum TipoTensor { float32, int8, uint8 }

/// Pre y posprocesamiento del Motor de Inferencia Edge AI, sin depender de TensorFlow Lite:
/// convierte el fotograma de la cámara en la entrada del modelo (rotación, letterbox y
/// normalización) y la salida del modelo en detecciones (decodificación, umbral y supresión de
/// no máximos). Separarlo del intérprete permite probarlo en el computador (Algoritmo 1).
class ProcesadorYolo {
  ProcesadorYolo({
    required List<int> formaEntrada,
    required List<int> formaSalida,
    TipoTensor tipoEntrada = TipoTensor.float32,
    double escalaEntrada = 0,
    int ceroEntrada = 0,
    TipoTensor tipoSalida = TipoTensor.float32,
    double escalaSalida = 0,
    int ceroSalida = 0,
    int numClases = 0,
    double iouNms = 0.45,
    int maxDetecciones = 20,
    bool coordenadasNormalizadas = false,
  })  : _outShape = formaSalida,
        _tipoEntrada = tipoEntrada,
        _escalaEntrada = escalaEntrada,
        _ceroEntrada = ceroEntrada,
        _tipoSalida = tipoSalida,
        _escalaSalida = escalaSalida,
        _ceroSalida = ceroSalida,
        _numClasses = numClases,
        _nmsIou = iouNms,
        _maxDet = maxDetecciones,
        _normalizedCoordinates = coordenadasNormalizadas,
        _nchw = formaEntrada[1] == 3 {
    // [1, H, W, 3] (TFLite clásico) o [1, 3, H, W] (LiteRT-Torch, Ultralytics ≥ 8.4.83)
    _inH = _nchw ? formaEntrada[2] : formaEntrada[1];
    _inW = _nchw ? formaEntrada[3] : formaEntrada[2];
    final elementos = formaEntrada.fold<int>(1, (a, b) => a * b);
    _inBytes = Uint8List(elementos * (tipoEntrada == TipoTensor.float32 ? 4 : 1));
  }

  final List<int> _outShape;
  final TipoTensor _tipoEntrada, _tipoSalida;
  final double _escalaEntrada, _escalaSalida;
  final int _ceroEntrada, _ceroSalida;
  final int _numClasses;
  final double _nmsIou;
  final int _maxDet;
  final bool _normalizedCoordinates;
  final bool _nchw;
  late final int _inH, _inW;
  late final Uint8List _inBytes;

  // Letterbox (igual que Ultralytics): la imagen se escala sin deformar y se rellena con gris.
  double _padX = 0, _padY = 0, _newW = 1, _newH = 1;

  /// Bytes de la entrada del modelo, listos para copiarse al tensor de entrada.
  Uint8List get entrada => _inBytes;

  /// Si la entrada del modelo es float32 (si no, está cuantizada a 8 bits).
  bool get entradaFloat => _inFloat;

  bool get _inFloat => _tipoEntrada == TipoTensor.float32;

  /// YUV420/BGRA -> RGB con letterbox y rotación ultra-rápida con tablas precalculadas.
  void preprocesar(Frame f) {
    final rot = f.rotation % 360;
    final rotW = (rot == 90 || rot == 270) ? f.height : f.width;
    final rotH = (rot == 90 || rot == 270) ? f.width : f.height;
    final esc = min(_inW / rotW, _inH / rotH);
    _newW = rotW * esc;
    _newH = rotH * esc;
    _padX = (_inW - _newW) / 2;
    _padY = (_inH - _newH) / 2;
    final floats = _inFloat ? _inBytes.buffer.asFloat32List() : null;
    final qs = _escalaEntrada == 0 ? 1.0 : _escalaEntrada;
    final qz = _ceroEntrada;
    final isInt8 = _tipoEntrada == TipoTensor.int8;
    final plane = _inH * _inW;
    final cStride = _nchw ? plane : 1;
    final pStride = _nchw ? 1 : 3;

    final invEsc = 1.0 / esc;
    const inv255 = 1.0 / 255.0;

    // Constantes de relleno gris (114) precalculadas fuera del bucle
    final padFloat = 114.0 * inv255;
    final padQ = ((114.0 * inv255) / qs + qz).round();
    final padByte = isInt8 ? padQ.clamp(-128, 127) & 0xFF : padQ.clamp(0, 255);

    // Tabla de mapeo horizontal para evitar 409,600 divisiones por frame
    final rxMap = Int32List(_inW);
    for (var ox = 0; ox < _inW; ox++) {
      rxMap[ox] = ((ox - _padX) * invEsc).floor();
    }

    final p0 = f.planes[0];
    final p1 = f.planes.length > 1 ? f.planes[1] : null;
    final p2 = f.planes.length > 2 ? f.planes[2] : null;
    final rStride0 = f.rowStrides[0];
    final rStride1 = f.rowStrides.length > 1 ? f.rowStrides[1] : 0;
    final pxStride1 = f.pixelStrides.length > 1 ? f.pixelStrides[1] : 1;

    var px = 0;
    for (var oy = 0; oy < _inH; oy++) {
      final ry = ((oy - _padY) * invEsc).floor();
      final filaFuera = ry < 0 || ry >= rotH;
      for (var ox = 0; ox < _inW; ox++) {
        final rx = rxMap[ox];
        final o = px * pStride;

        if (filaFuera || rx < 0 || rx >= rotW) {
          if (floats != null) {
            floats[o] = padFloat;
            floats[o + cStride] = padFloat;
            floats[o + 2 * cStride] = padFloat;
          } else {
            _inBytes[o] = padByte;
            _inBytes[o + cStride] = padByte;
            _inBytes[o + 2 * cStride] = padByte;
          }
          px++;
          continue;
        }

        int sx, sy;
        switch (rot) {
          case 90:
            sx = ry;
            sy = f.height - 1 - rx;
          case 180:
            sx = f.width - 1 - rx;
            sy = f.height - 1 - ry;
          case 270:
            sx = f.width - 1 - ry;
            sy = rx;
          default:
            sx = rx;
            sy = ry;
        }

        int r, g, b;
        if (f.isBgra) {
          final i = sy * rStride0 + sx * 4;
          b = p0[i];
          g = p0[i + 1];
          r = p0[i + 2];
        } else {
          final y = p0[sy * rStride0 + sx];
          final uvi = (sy >> 1) * rStride1 + (sx >> 1) * pxStride1;
          final u = p1![uvi] - 128;
          final v = p2![uvi] - 128;
          // Conversión entera fija YUV -> RGB (5x más rápida en CPUs móviles)
          r = (y + ((1436 * v) >> 10)).clamp(0, 255);
          g = (y - ((352 * u + 731 * v) >> 10)).clamp(0, 255);
          b = (y + ((1815 * u) >> 10)).clamp(0, 255);
        }

        if (floats != null) {
          floats[o] = r * inv255;
          floats[o + cStride] = g * inv255;
          floats[o + 2 * cStride] = b * inv255;
        } else {
          final qr = ((r * inv255) / qs + qz).round();
          final qg = ((g * inv255) / qs + qz).round();
          final qb = ((b * inv255) / qs + qz).round();
          _inBytes[o] = isInt8 ? qr.clamp(-128, 127) & 0xFF : qr.clamp(0, 255);
          _inBytes[o + cStride] =
              isInt8 ? qg.clamp(-128, 127) & 0xFF : qg.clamp(0, 255);
          _inBytes[o + 2 * cStride] =
              isInt8 ? qb.clamp(-128, 127) & 0xFF : qb.clamp(0, 255);
        }
        px++;
      }
    }
  }

  /// Caja en coordenadas normalizadas de la ENTRADA (0–1) -> normalizadas sobre el frame (quita el letterbox).
  Detection _det(
          int cls, double s, double x1, double y1, double x2, double y2) =>
      Detection(
          cls,
          s,
          (x1 * _inW - _padX) / _newW,
          (y1 * _inH - _padY) / _newH,
          (x2 * _inW - _padX) / _newW,
          (y2 * _inH - _padY) / _newH);

  /// Convierte los bytes del tensor de salida a números reales (descuantiza si hace falta).
  Float32List decuantizar(Uint8List bytes) {
    if (_tipoSalida == TipoTensor.float32) {
      final out = Float32List(bytes.length ~/ 4);
      out.buffer.asUint8List().setAll(0, bytes);
      return out;
    }
    final s = _escalaSalida, z = _ceroSalida;
    final signed = _tipoSalida == TipoTensor.int8;
    return Float32List.fromList(
        [for (final b in bytes) ((signed ? b.toSigned(8) : b) - z) * s]);
  }

  /// Decodifica la salida del modelo y aplica el umbral de confianza y la supresión de no máximos.
  List<Detection> postprocesar(Float32List out, double thr) {
    final a = _outShape[1], b = _outShape[2];
    final cand = <Detection>[];

    if (b == 6 && a <= 1000) {
      // End-to-end (sin NMS): [1, N, 6] = x1, y1, x2, y2, score, clase.
      final norm = _normalizedCoordinates
          ? 1.0
          : (_maxCoord(out, a, 6, true) > 2 ? 1.0 / _inW : 1.0);
      for (var i = 0; i < a; i++) {
        final s = out[i * 6 + 4];
        if (s < thr) continue;
        cand.add(_det(
            out[i * 6 + 5].round(),
            s,
            out[i * 6] * norm,
            out[i * 6 + 1] * norm,
            out[i * 6 + 2] * norm,
            out[i * 6 + 3] * norm));
      }
      return cand;
    }

    // YOLOv8/11: [1, 4+nc, N] (o transpuesto [1, N, 4+nc]).
    final transposed = a > b;
    final n = transposed ? a : b;
    final ch = transposed ? b : a;
    final nc = _numClasses > 0 ? min(ch - 4, _numClasses) : ch - 4;
    final norm = _normalizedCoordinates
        ? 1.0
        : (_maxCoord(out, n, ch, transposed) > 2 ? 1.0 / _inW : 1.0);

    for (var i = 0; i < n; i++) {
      var best = 0.0;
      var cls = -1;
      if (transposed) {
        final base = i * ch;
        for (var c = 0; c < nc; c++) {
          final s = out[base + 4 + c];
          if (s > best) {
            best = s;
            cls = c;
          }
        }
        if (best < thr) continue;
        final cx = out[base] * norm, cy = out[base + 1] * norm;
        final w = out[base + 2] * norm, h = out[base + 3] * norm;
        cand.add(
            _det(cls, best, cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2));
      } else {
        for (var c = 0; c < nc; c++) {
          final s = out[(4 + c) * n + i];
          if (s > best) {
            best = s;
            cls = c;
          }
        }
        if (best < thr) continue;
        final cx = out[i] * norm, cy = out[n + i] * norm;
        final w = out[2 * n + i] * norm, h = out[3 * n + i] * norm;
        cand.add(
            _det(cls, best, cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2));
      }
    }
    return supresionNoMaximos(cand, _nmsIou, _maxDet);
  }

  double _maxCoord(Float32List out, int n, int ch, bool rowMajor) {
    var m = 0.0;
    for (var i = 0; i < min(n, 200); i++) {
      final v = rowMajor ? out[i * ch + 2] : out[2 * n + i];
      if (v > m) m = v;
    }
    return m;
  }

  /// Supresión de no máximos: de las cajas de una misma clase que se solapan, queda la más segura.
  static List<Detection> supresionNoMaximos(List<Detection> d, double iouThr, int maxDet) {
    d.sort((x, y) => y.score.compareTo(x.score));
    final keep = <Detection>[];
    for (final c in d) {
      if (keep.length >= maxDet) break;
      if (keep.every((k) => k.cls != c.cls || interseccionSobreUnion(k, c) < iouThr)) keep.add(c);
    }
    return keep;
  }

  /// Intersección sobre la unión (IoU) de dos cajas.
  static double interseccionSobreUnion(Detection a, Detection b) {
    final iw = max(0.0, min(a.right, b.right) - max(a.left, b.left));
    final ih = max(0.0, min(a.bottom, b.bottom) - max(a.top, b.top));
    final inter = iw * ih;
    final ua = (a.right - a.left) * (a.bottom - a.top) +
        (b.right - b.left) * (b.bottom - b.top) -
        inter;
    return ua <= 0 ? 0 : inter / ua;
  }
}
