import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

import 'procesador_yolo.dart';

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
    _proc = ProcesadorYolo(
      formaEntrada: _inShape,
      formaSalida: _outShape,
      tipoEntrada: _tipo(inT.type),
      escalaEntrada: inT.params.scale,
      ceroEntrada: inT.params.zeroPoint,
      tipoSalida: _tipo(outT.type),
      escalaSalida: outT.params.scale,
      ceroSalida: outT.params.zeroPoint,
      numClases: _numClasses,
      iouNms: _nmsIou,
      maxDetecciones: _maxDet,
      coordenadasNormalizadas: _normalizedCoordinates,
    );
    info = ModelInfo(_inShape, inT.type.toString(), _outShape, used);
  }

  static TipoTensor _tipo(TensorType t) => t == TensorType.float32
      ? TipoTensor.float32
      : (t == TensorType.int8 ? TipoTensor.int8 : TipoTensor.uint8);

  late final Interpreter _interp;
  late final List<int> _inShape, _outShape;
  final int _numClasses;
  final double _nmsIou;
  final int _maxDet;
  final bool _normalizedCoordinates;
  late final ProcesadorYolo _proc;
  late final ModelInfo info;

  void close() => _interp.close();

  FrameResult process(Frame f, double threshold) {
    final sw = Stopwatch()..start();
    _proc.preprocesar(f);
    final pre = sw.elapsedMicroseconds / 1000;

    sw.reset();
    _interp.getInputTensor(0).data = _proc.entrada;
    _interp.invoke();
    final inf = sw.elapsedMicroseconds / 1000;

    sw.reset();
    final dets = _proc.postprocesar(_proc.decuantizar(_interp.getOutputTensor(0).data), threshold);
    final post = sw.elapsedMicroseconds / 1000;
    return FrameResult(dets, pre, inf, post);
  }

  List<double> benchmark(int warmup, int runs) {
    final rnd = Random(0);
    final entrada = _proc.entrada;
    for (var i = 0; i < entrada.length; i++) {
      entrada[i] = rnd.nextInt(256);
    }
    if (_proc.entradaFloat) {
      // Bytes aleatorios como float pueden dar NaN; usamos valores válidos 0–1.
      final f = entrada.buffer.asFloat32List();
      for (var i = 0; i < f.length; i++) {
        f[i] = rnd.nextDouble();
      }
    }
    final input = _interp.getInputTensor(0);
    final times = <double>[];
    final sw = Stopwatch();
    for (var i = 0; i < warmup + runs; i++) {
      input.data = entrada;
      sw
        ..reset()
        ..start();
      _interp.invoke();
      sw.stop();
      if (i >= warmup) times.add(sw.elapsedMicroseconds / 1000);
    }
    return times;
  }

}
