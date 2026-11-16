import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

/// Frame de cámara en formato transferible entre isolates.
class Frame {
  Frame({
    required this.width,
    required this.height,
    required this.planes,
    required this.rowStrides,
    required this.pixelStrides,
    required this.isBgra,
    required this.rotation,
  });

  final int width, height;
  final List<Uint8List> planes;
  final List<int> rowStrides;
  final List<int> pixelStrides;
  final bool isBgra; // iOS: BGRA8888 · Android: YUV420
  final int rotation; // 0/90/180/270, grados a girar para verlo derecho
}

class Detection {
  Detection(this.cls, this.score, this.left, this.top, this.right, this.bottom);
  final int cls;
  final double score;
  final double left,
      top,
      right,
      bottom; // normalizados 0–1 sobre el frame girado
}

class FrameResult {
  FrameResult(this.detections, this.preMs, this.infMs, this.postMs);
  final List<Detection> detections;
  final double preMs, infMs, postMs;
}

class ModelInfo {
  ModelInfo(
      this.inputShape, this.inputType, this.outputShape, this.delegateUsed);
  final List<int> inputShape;
  final String inputType;
  final List<int> outputShape;
  final String delegateUsed;
}

/// Isolate de larga vida que posee el Interpreter: preprocesa, infiere y postprocesa
/// fuera del hilo de UI para no contaminar la medición con jank de la interfaz.
class DetectorWorker {
  late final Isolate _isolate;
  late final SendPort _toWorker;
  final _fromWorker = ReceivePort();
  final _pending = <Completer<Object?>>[];

  static Future<DetectorWorker> spawn() async {
    final w = DetectorWorker();
    final ready = Completer<SendPort>();
    w._fromWorker.listen((msg) {
      if (msg is SendPort) {
        ready.complete(msg);
      } else {
        final c = w._pending.removeAt(0);
        msg is _WorkerError ? c.completeError(msg.message) : c.complete(msg);
      }
    });
    w._isolate = await Isolate.spawn(_main, w._fromWorker.sendPort);
    w._toWorker = await ready.future;
    return w;
  }

  Future<T> _call<T>(Object msg) {
    final c = Completer<Object?>();
    _pending.add(c);
    _toWorker.send(msg);
    return c.future.then((v) => v as T);
  }

  /// [numClasses]: clases reales del modelo. YOLOE-seg agrega 32 canales de máscara
  /// después de las clases; con este valor se ignoran. 0 = usar todos los canales.
  Future<ModelInfo> load(Uint8List model, String delegate, int threads,
          {int numClasses = 0,
          double nmsIou = 0.45,
          int maxDet = 20,
          bool normalizedCoordinates = false}) =>
      _call(_Load(TransferableTypedData.fromList([model]), delegate, threads,
          numClasses, nmsIou, maxDet, normalizedCoordinates));

  Future<FrameResult> process(Frame f, double threshold) =>
      _call(_Process(f, threshold));

  /// Solo invoke() sobre un tensor fijo: latencia pura del modelo, sin cámara.
  Future<List<double>> benchmark(int warmup, int runs) =>
      _call(_Bench(warmup, runs));

  void dispose() {
    _isolate.kill(priority: Isolate.immediate);
    _fromWorker.close();
  }
}

class _Load {
  _Load(this.model, this.delegate, this.threads, this.numClasses, this.nmsIou,
      this.maxDet, this.normalizedCoordinates);
  final TransferableTypedData model;
  final String delegate; // cpu | gpu | nnapi
  final int threads;
  final int numClasses;
  final double nmsIou;
  final int maxDet;
  final bool normalizedCoordinates;
}

class _Process {
  _Process(this.frame, this.threshold);
  final Frame frame;
  final double threshold;
}

class _Bench {
  _Bench(this.warmup, this.runs);
  final int warmup, runs;
}

class _WorkerError {
  _WorkerError(this.message);
  final String message;
}

void _main(SendPort toMain) {
  final port = ReceivePort();
  toMain.send(port.sendPort);
  _Engine? engine;
  port.listen((msg) {
    try {
      if (msg is _Load) {
        engine?.close();
        engine = _Engine(
            msg.model.materialize().asUint8List(),
            msg.delegate,
            msg.threads,
            msg.numClasses,
            msg.nmsIou,
            msg.maxDet,
            msg.normalizedCoordinates);
        toMain.send(engine!.info);
      } else if (msg is _Process) {
        toMain.send(engine!.process(msg.frame, msg.threshold));
      } else if (msg is _Bench) {
        toMain.send(engine!.benchmark(msg.warmup, msg.runs));
      }
    } catch (e) {
      toMain.send(_WorkerError(e.toString()));
    }
  });
}

class _Engine {
  _Engine(Uint8List model, String delegate, int threads, this._numClasses,
      this._nmsIou, this._maxDet, this._normalizedCoordinates) {
    final opts = InterpreterOptions()..threads = threads;
    var used = 'cpu (XNNPACK) x$threads';
    if (delegate == 'gpu') {
      opts.addDelegate(Platform.isAndroid ? GpuDelegateV2() : GpuDelegate());
      used = 'gpu';
    } else if (delegate == 'nnapi' && Platform.isAndroid) {
      opts.useNnApiForAndroid = true;
      used = 'nnapi';
    }
    _interp = Interpreter.fromBuffer(model, options: opts);
    _interp.allocateTensors();

    final inT = _interp.getInputTensor(0);
    final outT = _interp.getOutputTensor(0);
    _inShape = inT
        .shape; // [1, H, W, 3] (TFLite clásico) o [1, 3, H, W] (LiteRT-Torch, Ultralytics ≥8.4.83)
    _outShape =
        outT.shape; // [1, 84, N] (YOLOv8/11) o [1, N, 6] (end-to-end, YOLO26)
    _inType = inT.type;
    _inQ = inT.params;
    _outType = outT.type;
    _outQ = outT.params;
    _nchw = _inShape[1] == 3;
    _inH = _nchw ? _inShape[2] : _inShape[1];
    _inW = _nchw ? _inShape[3] : _inShape[2];
    _inBytes = Uint8List(inT.numBytes());
    info = ModelInfo(_inShape, _inType.toString(), _outShape, used);
  }

  late final Interpreter _interp;
  late final List<int> _inShape, _outShape;
  late final TensorType _inType, _outType;
  late final QuantizationParams _inQ, _outQ;
  final int _numClasses;
  final double _nmsIou;
  final int _maxDet;
  final bool _normalizedCoordinates;
  late final bool _nchw;
  late final int _inH, _inW;
  late final Uint8List _inBytes;
  late final ModelInfo info;
  // Letterbox (igual que Ultralytics): la imagen se escala sin deformar y se rellena con gris.
  double _padX = 0, _padY = 0, _newW = 1, _newH = 1;

  void close() => _interp.close();

  bool get _inFloat => _inType == TensorType.float32;

  FrameResult process(Frame f, double threshold) {
    final sw = Stopwatch()..start();
    _preprocess(f);
    final pre = sw.elapsedMicroseconds / 1000;

    sw.reset();
    _interp.getInputTensor(0).data = _inBytes;
    _interp.invoke();
    final inf = sw.elapsedMicroseconds / 1000;

    sw.reset();
    final dets = _postprocess(threshold);
    final post = sw.elapsedMicroseconds / 1000;
    return FrameResult(dets, pre, inf, post);
  }

  List<double> benchmark(int warmup, int runs) {
    final rnd = Random(0);
    for (var i = 0; i < _inBytes.length; i++) {
      _inBytes[i] = rnd.nextInt(256);
    }
    if (_inFloat) {
      // Bytes aleatorios como float pueden dar NaN; usamos valores válidos 0–1.
      final f = _inBytes.buffer.asFloat32List();
      for (var i = 0; i < f.length; i++) {
        f[i] = rnd.nextDouble();
      }
    }
    final input = _interp.getInputTensor(0);
    final times = <double>[];
    final sw = Stopwatch();
    for (var i = 0; i < warmup + runs; i++) {
      input.data = _inBytes;
      sw
        ..reset()
        ..start();
      _interp.invoke();
      sw.stop();
      if (i >= warmup) times.add(sw.elapsedMicroseconds / 1000);
    }
    return times;
  }

  /// YUV420/BGRA -> RGB con letterbox y rotación ultra-rápida con tablas precalculadas.
  void _preprocess(Frame f) {
    final rot = f.rotation % 360;
    final rotW = (rot == 90 || rot == 270) ? f.height : f.width;
    final rotH = (rot == 90 || rot == 270) ? f.width : f.height;
    final esc = min(_inW / rotW, _inH / rotH);
    _newW = rotW * esc;
    _newH = rotH * esc;
    _padX = (_inW - _newW) / 2;
    _padY = (_inH - _newH) / 2;
    final floats = _inFloat ? _inBytes.buffer.asFloat32List() : null;
    final qs = _inQ.scale == 0 ? 1.0 : _inQ.scale;
    final qz = _inQ.zeroPoint;
    final isInt8 = _inType == TensorType.int8;
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

  Float32List _readOutput() {
    final bytes = _interp.getOutputTensor(0).data;
    if (_outType == TensorType.float32) {
      final out = Float32List(bytes.length ~/ 4);
      out.buffer.asUint8List().setAll(0, bytes);
      return out;
    }
    final s = _outQ.scale, z = _outQ.zeroPoint;
    final signed = _outType == TensorType.int8;
    return Float32List.fromList(
        [for (final b in bytes) ((signed ? b.toSigned(8) : b) - z) * s]);
  }

  List<Detection> _postprocess(double thr) {
    final out = _readOutput();
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
    return _nms(cand, _nmsIou, _maxDet);
  }

  double _maxCoord(Float32List out, int n, int ch, bool rowMajor) {
    var m = 0.0;
    for (var i = 0; i < min(n, 200); i++) {
      final v = rowMajor ? out[i * ch + 2] : out[2 * n + i];
      if (v > m) m = v;
    }
    return m;
  }

  List<Detection> _nms(List<Detection> d, double iouThr, int maxDet) {
    d.sort((x, y) => y.score.compareTo(x.score));
    final keep = <Detection>[];
    for (final c in d) {
      if (keep.length >= maxDet) break;
      if (keep.every((k) => k.cls != c.cls || _iou(k, c) < iouThr)) keep.add(c);
    }
    return keep;
  }

  double _iou(Detection a, Detection b) {
    final iw = max(0.0, min(a.right, b.right) - max(a.left, b.left));
    final ih = max(0.0, min(a.bottom, b.bottom) - max(a.top, b.top));
    final inter = iw * ih;
    final ua = (a.right - a.left) * (a.bottom - a.top) +
        (b.right - b.left) * (b.bottom - b.top) -
        inter;
    return ua <= 0 ? 0 : inter / ua;
  }
}
