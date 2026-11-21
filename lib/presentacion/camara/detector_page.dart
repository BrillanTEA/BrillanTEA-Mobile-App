import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../dominio/accesibilidad_service.dart';
import '../../dominio/catalogo_service.dart';
import '../../dominio/registro_uso_service.dart';
import '../../dominio/rutinas_app.dart';
import '../../infraestructura/detector_worker.dart';
import '../../infraestructura/modo_compilacion.dart';
import '../../infraestructura/perfil_yolo26.dart';
import '../../infraestructura/servicio_voz.dart';
import '../../infraestructura/stats.dart';
import '../rutinas/rutinas_page.dart';
import 'realidad_aumentada.dart';

/// Umbral del proyecto: latencia de extremo a extremo por frame.
const double kObjetivoMs = 150;

// Panel técnico (modelo, CPU/GPU, hilos, benchmark, CSV): kModoTecnico, definido en
// modo_compilacion.dart. Solo aparece en la versión QA (--dart-define=QA=true).

/// Tamaño de la tarjeta de realidad aumentada que acompaña a cada objeto.

/// Representa una detección emparejada con el catálogo clínico ARASAAC.
class DetectedObjectItem {
  final CatalogoItem item;
  final double score;
  final Detection detection;

  const DetectedObjectItem({
    required this.item,
    required this.score,
    required this.detection,
  });
}

class DetectorPage extends StatefulWidget {
  const DetectorPage({super.key});

  @override
  State<DetectorPage> createState() => _DetectorPageState();
}

class _DetectorPageState extends State<DetectorPage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  CameraController? _cam;
  DetectorWorker? _worker;
  DetectorWorker? _worker2; // segundo modelo del modo DOBLE
  ModelInfo? _info;

  // Modo DOBLE: YOLO11s original de COCO para las 23 clases de COCO + YOLO26s propio para las 11 clases
  // restantes (examen: 90,5 % de precisión). Las clases que no se usan van como "-" en los .txt.
  static const _dual = 'DOBLE: COCO + propio (recomendado)';
  static const _fCocoBase16 =
      'assets/models/coco_base_fp16.tflite'; // mismo modelo en FP16 (mitad de peso)
  static const _fCocoBase =
      'assets/models/coco_base_fp32.tflite'; // YOLO11s COCO elegido por paso8
  static const _fCocoS =
      'assets/models/yolo11s_640_fp32.tflite'; // YOLO11s COCO (más preciso, se usa si existe)
  static const _fCocoN =
      'assets/models/yolo11n_640_fp32.tflite'; // YOLO11n COCO (respaldo)
  String _fCoco = _fCocoN;
  // Modelo propio: el de 11 clases (paso8) si está en assets; si no, el anterior de 34 clases.
  static const _fProp11_16 =
      'assets/models/propio11_fp16.tflite'; // modelo propio en FP16 (exportar_fp16.py)
  static const _fProp11 = 'assets/models/propio11_fp32.tflite';
  static const _lProp11 = 'assets/models/propio11.txt';
  String _actualFProp = 'assets/models/yolo11n_propio_fp32.tflite';
  static const _fUmbrales =
      'assets/models/umbrales_app.json'; // umbral por objeto (umbrales_combo.py)
  Map<String, double> _umbralClase =
      {}; // clave del catálogo -> umbral mínimo para mostrarlo
  bool _worker2Activo = false;
  static const _lCoco =
      'assets/models/dual_coco.txt'; // 80 líneas: clave del catálogo o "-"
  String _lProp =
      'assets/models/dual_propio.txt'; // 34 líneas (modelo anterior) o 11 (propio11.txt)
  int _offset2 =
      0; // las clases del 2.º modelo van después de las del 1.º en _labels

  /// El modelo devuelve todo lo que supere el umbral más bajo; luego cada objeto se filtra con el suyo.
  double get _umbralWorker {
    var m = _threshold;
    for (final u in _umbralClase.values) {
      if (u < m) m = u;
    }
    return m;
  }

  bool _deteccionDelCatalogo(Detection d) {
    if (!PerfilYolo26.permite(d.cls, d.score) || d.cls >= _labels.length) {
      return false;
    }
    if (![d.left, d.top, d.right, d.bottom].every((v) => v.isFinite) ||
        d.right <= d.left ||
        d.bottom <= d.top) {
      return false;
    }
    return _catalogo.findByClave(_labels[d.cls]) != null &&
        PerfilYolo26.claves.contains(_labels[d.cls]);
  }

  double _umbralDe(Detection d) => _umbralClase[_labels[d.cls]] ?? _threshold;

  // Objetos grandes de COCO que el modelo propio confunde con una clase suya (laptop -> cuaderno, tele -> caja...).
  static const _cocoQueTapan = {
    'laptop',
    'televisor',
    'mochila',
    'refrigeradora',
    'silla',
    'sofa'
  };

  /// Si el modelo COCO (más preciso) ya ve un objeto en el mismo lugar, se descarta lo que dice
  /// el modelo propio ahí. Ej.: la laptop deja de salir también como "cuaderno".
  double _area(Detection d) =>
      max(0.0, d.right - d.left) * max(0.0, d.bottom - d.top);
  double _inter(Detection a, Detection b) =>
      max(0.0, min(a.right, b.right) - max(a.left, b.left)) *
      max(0.0, min(a.bottom, b.bottom) - max(a.top, b.top));

  /// Cuánto supera cada detección su propio umbral (+0.10 si viene del modelo COCO, que es más preciso).
  double _margen(Detection d) =>
      d.score -
      _umbralDe(d) +
      (_model == _dual && d.cls < _offset2 ? 0.10 : 0.0);

  /// Un objeto = un solo nombre. Si dos detecciones de clases distintas cubren casi lo mismo
  /// (laptop y cuaderno, taza y vaso...), se queda solo la más segura.
  List<Detection> _unaPorLugar(List<Detection> ds) {
    final orden = List<Detection>.from(ds)
      ..sort((a, b) => _margen(b).compareTo(_margen(a)));
    final keep = <Detection>[];
    for (final d in orden) {
      final ad = _area(d);
      final choca = keep.any((k) {
        final ak = _area(k), i = _inter(d, k);
        final iou = i / (ad + ak - i + 1e-9);
        final chica = min(ad, ak), grande = max(ad, ak);
        return iou >= 0.5 || (i >= 0.8 * chica && grande <= 2.5 * chica);
      });
      if (!choca) keep.add(d);
    }
    return keep;
  }

  List<Detection> _suprimirPropias(List<Detection> ds) {
    final coco =
        ds.where((d) => d.cls < _offset2 && d.score >= _umbralDe(d)).toList();
    if (coco.isEmpty) return ds;
    double area(double l, double t, double r, double b) =>
        max(0.0, r - l) * max(0.0, b - t);
    return ds.where((p) {
      if (p.cls < _offset2) return true;
      final ap = area(p.left, p.top, p.right, p.bottom);
      for (final c in coco) {
        final inter = area(max(p.left, c.left), max(p.top, c.top),
            min(p.right, c.right), min(p.bottom, c.bottom));
        final ac = area(c.left, c.top, c.right, c.bottom);
        final iou = inter / (ap + ac - inter + 1e-9);
        if (iou >= 0.45) return false;
        if (_cocoQueTapan.contains(_labels[c.cls]) &&
            inter >= 0.7 * ap &&
            ac <= 4 * ap) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<String> _models = [];
  List<String> _labels = [];
  String? _model;
  String _delegate = 'cpu';
  int _threads = 4;
  int _extraRotation = 0;
  double _threshold = 0.25; // se cambia al cargar el modelo
  ResolutionPreset _resolution = ResolutionPreset.high; // 720p

  final _catalogo = CatalogoService();
  final _tts = ServicioVoz();
  bool _autoVoice = false;
  String? _lastSpokenKey;
  DateTime? _lastSpokenTime;

  bool _busy = false;
  bool _running = false;
  String? _error;
  String _benchText = '';
  List<Detection> _dets = [];

  // Objetos detectados: 1 tarjeta grande o 2 lado a lado
  List<DetectedObjectItem> _detectedItems = [];
  List<DetectedObjectItem> _persistedItems = [];
  String? _persistedFoco;
  int _framesSinDeteccion = 0;
  DetectedObjectItem? _objetoDetectadoTutorial;
  bool _noReconocidoTutorial = false; // modo tutorial: se tocó el botón y no se reconoció ningún objeto
  String? _focusedClave;
  int _maxObjetosSimultaneos = 2; // TEA Nivel 2: máximo 2 objetos en pantalla
  bool _mostrarPanelMetricas = false;
  bool _mostrarCajasDebug = false;

  // Filtro temporal: un objeto se confirma si aparece en 2 de los últimos 3 frames.
  static const _ventana = 3, _minVistos = 2;
  final List<Set<int>> _historial = [];
  bool _filtroTemporal = true;
  final _pre = LatencyStats(),
      _inf = LatencyStats(),
      _post = LatencyStats(),
      _e2e = LatencyStats();
  final _fpsWatch = Stopwatch();
  int _frames = 0;
  double _fps = 0;
  DateTime? _sessionStart;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AccesibilidadService().addListener(_onAccesibilidadChange);
    _init();
  }

  /// Pausa la cámara cuando la app pasa a segundo plano (privacidad y batería) y la reanuda al volver.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final cam = _cam;
      if (cam == null) return;
      _cam = null;
      _running = false;
      _dets = [];
      _detectedItems = [];
      cam.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      if (_cam == null && _worker != null && mounted) {
        _startCamera().catchError((Object e) {
          if (mounted) {
            setState(() => _error = 'No se pudo reanudar la cámara: $e');
          }
        });
      }
    }
  }

  void _onAccesibilidadChange() {
    if (mounted) setState(() {});
  }

  Future<void> _init() async {
    try {
      await _catalogo.load();
      await _tts.setLanguage('es');
      await _tts.setSpeechRate(0.45);

      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _models = manifest
          .listAssets()
          .where((a) => a.endsWith('.tflite'))
          .toList()
        ..sort();
      if (!_models.contains(PerfilYolo26.asset)) {
        throw StateError('Falta el candidato YOLO26 de35clases');
      }
      _models = [
        PerfilYolo26.asset
      ]; // Copia de diagnóstico: ningún modelo anterior activo.

      // Filtrar modelos con formato w8a32 (LiteRT Torch) que generan "failed precondition"
      // por incompatibilidad con el runtime de TFLite en Android
      _models.removeWhere((m) => m.contains('w8a32'));
      try {
        final j = jsonDecode(await rootBundle.loadString(_fUmbrales))
            as Map<String, dynamic>;
        _umbralClase = {
          for (final e in (j['umbrales'] as Map<String, dynamic>).entries)
            e.key: (e.value as num).toDouble()
        };
      } catch (_) {
        _umbralClase = {}; // sin archivo: se usa el umbral general (0.50)
      }
      // COCO: coco_base (YOLO11s elegido por paso8) > YOLO11s > YOLO11n.
      // FP16 primero si existe: mismo modelo, mitad de peso en el APK (RNF-05)
      _fCoco = _models.contains(_fCocoBase16)
          ? _fCocoBase16
          : (_models.contains(_fCocoBase)
              ? _fCocoBase
              : (_models.contains(_fCocoS) ? _fCocoS : _fCocoN));
      if (manifest.listAssets().contains(_lProp11)) {
        if (_models.contains(_fProp11_16)) {
          _actualFProp = _fProp11_16;
          _lProp = _lProp11;
        } else if (_models.contains(_fProp11)) {
          _actualFProp = _fProp11;
          _lProp = _lProp11;
        }
      }
      if (_models.contains(_fCoco) && _models.contains(_actualFProp)) {
        _models.insert(0, _dual); // sistema de dos modelos por defecto
      }

      // Por defecto, el modo DOBLE; si faltan sus archivos, YOLO11n de COCO como respaldo.
      _model = _models.contains(_dual)
          ? _dual
          : _models.firstWhere(
              (m) => m.contains('yolo11n_640_fp32'),
              orElse: () => _models.firstWhere((m) => m.contains('yolo11n'),
                  orElse: () => _models.first),
            );

      _worker = await DetectorWorker.spawn();
      _worker2 = await DetectorWorker.spawn();
      await _loadModel();
      await _startCamera();
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _loadModel() async {
    setState(() {
      _info = null;
      _error = null;
    });
    if (_model == _dual) {
      final b1 = (await rootBundle.load(_fCoco)).buffer.asUint8List();
      final l1 = (await rootBundle.loadString(_lCoco)).trim().split('\n');
      _labels = [...l1];
      _offset2 = l1.length;
      _historial.clear();
      _threshold =
          0.5; // umbral general con el que se midió el examen (si no hay umbral por objeto)
      try {
        _info =
            await _worker!.load(b1, _delegate, _threads, numClasses: l1.length);
        if (!_actualFProp.contains('w8a32')) {
          try {
            final b2 =
                (await rootBundle.load(_actualFProp)).buffer.asUint8List();
            final l2 = (await rootBundle.loadString(_lProp)).trim().split('\n');
            await _worker2!
                .load(b2, _delegate, _threads, numClasses: l2.length);
            _labels.addAll(l2);
            _worker2Activo = true;
          } catch (e) {
            _worker2Activo = false;
            _error = 'No cargó el modelo propio ($_actualFProp): $e';
          }
        } else {
          _worker2Activo = false;
        }
        _resetStats();
      } catch (e) {
        _error = 'No se pudo cargar con delegado "$_delegate": $e';
      }
      if (mounted) setState(() {});
      return;
    }

    _worker2Activo = false;

    final bytes = (await rootBundle.load(_model!)).buffer.asUint8List();
    try {
      _labels =
          (await rootBundle.loadString(_model!.replaceAll('.tflite', '.txt')))
              .trim()
              .split('\n');
    } catch (_) {
      if (_model == PerfilYolo26.asset) rethrow;
      _labels = (await rootBundle.loadString('assets/labels_coco.txt'))
          .trim()
          .split('\n');
    }
    _historial.clear();
    _threshold = 0.25; // umbral del modo de un solo modelo (panel técnico)
    if (_model == PerfilYolo26.asset) {
      PerfilYolo26.validarEtiquetas(_labels);
      if (sha256.convert(bytes).toString() != PerfilYolo26.sha256Modelo) {
        throw StateError(
            'El archivo del modelo no coincide con el candidato verificado');
      }
      _umbralClase
          .clear(); // Los umbrales históricos de otros pesos no son aplicables.
      _threshold = PerfilYolo26.confianza;
    }
    try {
      _info = await _worker!.load(bytes, _delegate, _threads,
          numClasses: _labels.length,
          nmsIou: PerfilYolo26.iouNms,
          maxDet: PerfilYolo26.maxDet,
          normalizedCoordinates: true);
      if (_model == PerfilYolo26.asset) {
        PerfilYolo26.validarTensores(
            _info!.inputShape, _info!.outputShape, _info!.inputType);
      }
      _resetStats();
    } catch (e) {
      _error = 'No se pudo cargar con delegado "$_delegate": $e';
    }
    if (mounted) setState(() {});
  }

  Future<void> _startCamera() async {
    await _cam?.dispose();
    final cams = await availableCameras();
    final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first);
    final cam = CameraController(
      back,
      _resolution,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );
    await cam.initialize();
    _cam = cam;
    await cam.startImageStream(_onFrame);
    _running = true;
    _fpsWatch
      ..reset()
      ..start();
    if (mounted) setState(() {});
  }

  void _resetStats() {
    for (final s in [_pre, _inf, _post, _e2e]) {
      s.clear();
    }
    _frames = 0;
    _sessionStart = DateTime.now();
  }

  void _speak(String text) async {
    if (text.isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _onFrame(CameraImage img) async {
    if (_busy || _info == null || !_running) return;
    _busy = true;
    final t0 = DateTime.now();
    final frame = Frame(
      width: img.width,
      height: img.height,
      planes: [for (final p in img.planes) p.bytes],
      rowStrides: [for (final p in img.planes) p.bytesPerRow],
      pixelStrides: [for (final p in img.planes) p.bytesPerPixel ?? 1],
      isBgra: img.format.group == ImageFormatGroup.bgra8888,
      rotation: (_cam!.description.sensorOrientation + _extraRotation) % 360,
    );
    try {
      final FrameResult r;
      if (_model == _dual && _worker2Activo) {
        // Los dos modelos corren en paralelo (cada uno en su isolate) sobre el mismo frame.
        FrameResult r1;
        FrameResult? r2;
        try {
          final rs = await Future.wait([
            _worker!.process(frame, _umbralWorker),
            _worker2!.process(frame, _umbralWorker),
          ]);
          r1 = rs[0];
          r2 = rs[1];
        } catch (_) {
          // Si el segundo modelo da error de delegado o tipo, inferir con el modelo primario sin bloquear la cámara
          _worker2Activo = false;
          r1 = await _worker!.process(frame, _umbralWorker);
        }
        final todas = [
          ...r1.detections,
          if (r2 != null)
            for (final d in r2.detections)
              Detection(
                  d.cls + _offset2, d.score, d.left, d.top, d.right, d.bottom),
        ].where(_deteccionDelCatalogo).toList();
        // Los dos modelos corren EN PARALELO: el tiempo real de cada etapa es el del más lento (no la suma).
        r = FrameResult(
            _suprimirPropias(todas),
            max(r1.preMs, r2?.preMs ?? 0.0),
            max(r1.infMs, r2?.infMs ?? 0.0),
            max(r1.postMs, r2?.postMs ?? 0.0));
      } else {
        r = await _worker!.process(frame, _umbralWorker);
      }

      final e2e = DateTime.now().difference(t0).inMicroseconds / 1000;
      _pre.add(r.preMs);
      _inf.add(r.infMs);
      _post.add(r.postMs);
      _e2e.add(e2e);
      _frames++;
      if (_fpsWatch.elapsedMilliseconds > 1000) {
        _fps = _frames * 1000 / _fpsWatch.elapsedMilliseconds;
        _frames = 0;
        _fpsWatch
          ..reset()
          ..start();
      }

      // 1) Umbral por objeto (umbrales_app.json, elegido con fotos etiquetadas por personas).
      final validas = r.detections
          .where(_deteccionDelCatalogo)
          .where((d) => d.score >= _umbralDe(d))
          .toList();
      _historial.add({for (final d in validas) d.cls});
      if (_historial.length > _ventana) _historial.removeAt(0);
      // 2) Filtro temporal: un objeto se muestra si aparece en 2 de los últimos 3 frames,
      //    o al instante si el modelo está MUY seguro (umbral + 0.25). Evita objetos "inventados".
      final estables = _filtroTemporal
          ? validas.where((d) {
              if (d.score >= _umbralDe(d) + 0.25) return true;
              return _historial.where((h) => h.contains(d.cls)).length >=
                  _minVistos;
            }).toList()
          : validas;
      // 3) Un solo nombre por objeto: si dos cajas tapan la misma cosa, gana la más segura.
      final limpias = _unaPorLugar(estables);
      final vista = limpias;

      final ordenados = List<Detection>.from(vista)
        ..sort((a, b) => b.score.compareTo(a.score));

      final List<DetectedObjectItem> matchedList = [];
      final Set<String> seenClaves = {};

      for (final d in ordenados) {
        if (d.cls >= 0 && d.cls < _labels.length) {
          final label = _labels[d.cls];
          if (label == '-') continue;
          final matched = _catalogo.findPorEtiqueta(label);
          if (matched != null && !seenClaves.contains(matched.clave)) {
            seenClaves.add(matched.clave);
            matchedList.add(DetectedObjectItem(
              item: matched,
              score: d.score,
              detection: d,
            ));
            if (matchedList.length >= _maxObjetosSimultaneos) {
              break;
            }
          }
        }
      }

      // Preservar foco seleccionado si aún está presente, si no, enfocar el primero
      String? nuevoFoco = _focusedClave;
      if (matchedList.isNotEmpty) {
        final focoPresente = matchedList.any((m) => m.item.clave == nuevoFoco);
        if (!focoPresente) {
          nuevoFoco = matchedList.first.item.clave;
        }
      } else {
        nuevoFoco = null;
      }

      // Estabilización de UI: mantener detecciones activas 2 frames para evitar parpadeos
      List<DetectedObjectItem> activeItems;
      String? activeFoco;
      if (matchedList.isNotEmpty) {
        _persistedItems = matchedList;
        _persistedFoco = nuevoFoco;
        _framesSinDeteccion = 0;
        activeItems = matchedList;
        activeFoco = nuevoFoco;
      } else {
        _framesSinDeteccion++;
        if (_framesSinDeteccion <= 2 && _persistedItems.isNotEmpty) {
          activeItems = _persistedItems;
          activeFoco = _persistedFoco;
        } else {
          _persistedItems = [];
          _persistedFoco = null;
          activeItems = [];
          activeFoco = null;
        }
      }

      // Auto-voz si está habilitada (solo en modo automático, no interrumpe el tutorial)
      final esTutorial = AccesibilidadService().tutorialCamara;
      if (!esTutorial &&
          _autoVoice &&
          activeItems.isNotEmpty &&
          activeFoco != null) {
        final focusedObj = activeItems.firstWhere(
          (m) => m.item.clave == activeFoco,
          orElse: () => activeItems.first,
        );
        final now = DateTime.now();
        final diff = _lastSpokenTime == null
            ? 9999
            : now.difference(_lastSpokenTime!).inSeconds;
        if (_lastSpokenKey != focusedObj.item.clave || diff >= 3) {
          _lastSpokenKey = focusedObj.item.clave;
          _lastSpokenTime = now;
          final frase = focusedObj.item.fraseApoyo ?? focusedObj.item.nombre;
          _speak(frase);
        }
      }

      if (mounted) {
        setState(() {
          _dets = vista;
          _detectedItems = activeItems;
          _focusedClave = activeFoco;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
        if (e.toString().contains('failed precondition') ||
            e.toString().contains('kTfLiteError')) {
          _recuperarAModeloSeguro();
        }
      }
    } finally {
      _busy = false;
    }
  }

  bool _recuperando = false;
  Future<void> _recuperarAModeloSeguro() async {
    if (_model == PerfilYolo26.asset) {
      _running = false;
      await _cam?.stopImageStream();
      if (mounted) {
        setState(() => _error =
            'El candidato no pudo ejecutarse. Prueba CPU y conserva este error para el diagnóstico.');
      }
      return; // No sustituir silenciosamente por un modelo COCO de80clases.
    }
    if (_recuperando) return;
    _recuperando = true;
    try {
      debugPrint('Recuperando automáticamente a modelo seguro YOLO11n FP32...');
      _model = _fCocoN;
      await _loadModel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Modelo adaptado automáticamente a YOLO11n FP32 para estabilidad continua.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {}
    _recuperando = false;
  }

  Future<void> _runBenchmark() async {
    setState(
        () => _benchText = 'Midiendo… (10 de calentamiento + 100 corridas)');
    _running = false;
    while (_busy) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    try {
      String linea(String nombre, List<double> t) {
        final mean = t.reduce((a, b) => a + b) / t.length;
        return '$nombre: media ${mean.toStringAsFixed(1)} · '
            'p50 ${LatencyStats.percentile(t, 50).toStringAsFixed(1)} · '
            'p95 ${LatencyStats.percentile(t, 95).toStringAsFixed(1)} ms';
      }

      final t1 = await _worker!.benchmark(10, 100);
      _benchText = linea(_model == _dual ? 'COCO' : 'invoke()', t1);
      if (_model == _dual && _worker2Activo) {
        // Cada modelo por separado; en uso real corren a la vez, así que también se mide juntos.
        final t2 = await _worker2!.benchmark(10, 100);
        final juntos = await Future.wait(
            [_worker!.benchmark(5, 50), _worker2!.benchmark(5, 50)]);
        final par = [
          for (var i = 0; i < 50; i++) max(juntos[0][i], juntos[1][i])
        ];
        _benchText =
            '${linea('COCO', t1)}\n${linea('Propio', t2)}\n${linea('Los dos a la vez', par)}';
      }
    } catch (e) {
      _benchText = 'Error: $e';
    }
    _running = true;
    if (mounted) setState(() {});
  }

  Future<void> _copyReport() async {
    final dur = _sessionStart == null
        ? 0
        : DateTime.now().difference(_sessionStart!).inSeconds;
    final b = StringBuffer()
      ..writeln('modelo,${_model!.split('/').last}')
      ..writeln('delegado,${_info?.delegateUsed}')
      ..writeln('entrada,${_info?.inputShape} ${_info?.inputType}')
      ..writeln('salida,${_info?.outputShape}')
      ..writeln('camara,${_cam?.value.previewSize} ($_resolution)')
      ..writeln(
          'build,${kReleaseMode ? 'release' : kProfileMode ? 'profile' : 'DEBUG (no válido para medir)'}')
      ..writeln('duracion_s,$dur')
      ..writeln('frames,${_e2e.all.length}')
      ..writeln(
          'fps_promedio,${dur > 0 ? (_e2e.all.length / dur).toStringAsFixed(2) : '-'}')
      ..writeln('hilos,$_threads')
      ..writeln('benchmark,$_benchText')
      ..writeln()
      ..writeln('frame,pre_ms,inf_ms,post_ms,e2e_ms');
    for (var i = 0; i < _e2e.all.length; i++) {
      b.writeln(
          '$i,${_pre.all[i].toStringAsFixed(2)},${_inf.all[i].toStringAsFixed(2)},'
          '${_post.all[i].toStringAsFixed(2)},${_e2e.all[i].toStringAsFixed(2)}');
    }
    await Clipboard.setData(ClipboardData(text: b.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV copiado (${_e2e.all.length} frames)')),
      );
    }
    // Además se guarda como archivo y se abre la hoja de compartir (Gmail, Drive, WhatsApp…),
    // para analizar las mediciones en una computadora.
    try {
      final ahora = DateTime.now();
      final sello =
          '${ahora.year}${ahora.month.toString().padLeft(2, '0')}${ahora.day.toString().padLeft(2, '0')}'
          '_${ahora.hour.toString().padLeft(2, '0')}${ahora.minute.toString().padLeft(2, '0')}';
      final delegado = (_info?.delegateUsed ?? _delegate)
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '');
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/latencia_${delegado}_$sello.csv');
      await f.writeAsString(b.toString());
      await SharePlus.instance.share(ShareParams(
        files: [XFile(f.path, mimeType: 'text/csv')],
        subject: 'Latencia Brillantea $sello',
      ));
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AccesibilidadService().removeListener(_onAccesibilidadChange);
    _cam?.dispose();
    _worker?.dispose();
    _worker2?.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cam = _cam;
    final esTutorial = AccesibilidadService().tutorialCamara;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Cabecera
            _buildHeader(esTutorial),

            // 2. Visor de la cámara
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    color: const Color(0xFF8B8075),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (cam == null || !cam.value.isInitialized)
                          Center(
                            child: Text(
                              _error ?? 'Iniciando cámara…',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                          )
                        else
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: cam.value.previewSize?.height ?? 1,
                              height: cam.value.previewSize?.width ?? 1,
                              child: CameraPreview(cam),
                            ),
                          ),

                        if (_mostrarCajasDebug)
                          CustomPaint(
                              painter: _BoxPainter(
                                  _dets, _labels, _catalogo, _tamanoFrame())),

                        // CONTENIDO ADAPTATIVO:
                        if (esTutorial) ...[
                          // En modo tutorial:
                          // Al pulsar el botón obturador se muestra la tarjeta informativa abajo, manteniendo la cámara limpia.
                          if (_noReconocidoTutorial)
                            Positioned.fill(child: _buildNoReconocido())
                          else if (_objetoDetectadoTutorial != null) ...[
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 16,
                              child: _buildCardAbajo(_objetoDetectadoTutorial!),
                            ),
                          ] else
                            _buildGuiaApuntadoTutorial(),
                        ] else ...[
                          // EN MODO DETECCIÓN AUTOMÁTICA: realidad aumentada en el espacio de pantalla.
                          // Cada objeto reconocido (máx. 2) lleva su tarjeta con pictograma y nombre
                          // junto a él, y la tarjeta se mueve con el objeto en cada fotograma.
                          if (_detectedItems.isNotEmpty)
                            Positioned.fill(
                              child: LayoutBuilder(
                                builder: (ctx, c) =>
                                    _capaRealidadAumentada(c.biggest),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Botón del modo tutorial
            if (esTutorial && !_noReconocidoTutorial) _buildBotonCamaraTutorial(),

            // 4. Panel técnico (solo en modo técnico)
            if (kModoTecnico && _mostrarPanelMetricas)
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '⚙️ Métricas de Tesis y Control de Inferencia',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          IconButton(
                            tooltip: 'Cerrar',
                            icon: const Icon(Icons.close,
                                color: Colors.white70, size: 20),
                            onPressed: () =>
                                setState(() => _mostrarPanelMetricas = false),
                          ),
                        ],
                      ),
                    ),
                    // Botones de la prueba de latencia (OE4-I1), siempre visibles arriba del panel
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                      child: Row(
                        children: [
                          Expanded(
                              child: _botonMedicion(
                                  Icons.speed, 'Benchmark', _runBenchmark)),
                          const SizedBox(width: 6),
                          Expanded(
                              child: _botonMedicion(Icons.restart_alt,
                                  'Reiniciar', () => setState(_resetStats))),
                          const SizedBox(width: 6),
                          Expanded(
                              child: _botonMedicion(Icons.ios_share,
                                  'Exportar CSV', _copyReport)),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.45),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14.0),
                              child: _statsCard(),
                            ),
                            _controls(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool esTutorial) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                  button: true,
                  label: 'Volver',
                  child: InkWell(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFDDD6C9), width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back,
                            color: Color(0xFF3A3A3A), size: 22),
                      ),
                    ),
                  )),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Cámara',
                  style: TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ),
              // Conmutador rápido de modo: Tutorial vs Detección Automática
              InkWell(
                onTap: () {
                  final nuevo = !esTutorial;
                  setState(() {
                    _objetoDetectadoTutorial = null;
                    _noReconocidoTutorial = false;
                  });
                  AccesibilidadService().setTutorialCamara(nuevo);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: esTutorial
                        ? const Color(0xFFE8F2F4)
                        : const Color(0xFFF7F5F0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: esTutorial
                          ? const Color(0xFF386673)
                          : const Color(0xFFDDD6C9),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        esTutorial
                            ? Icons.touch_app_rounded
                            : Icons.auto_awesome_rounded,
                        size: 15,
                        color: esTutorial
                            ? const Color(0xFF386673)
                            : const Color(0xFF757575),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        esTutorial ? 'Tutorial' : 'Auto',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: esTutorial
                              ? const Color(0xFF386673)
                              : const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Botón discreto para panel de métricas de tesis (solo en modo técnico)
              if (kModoTecnico)
                IconButton(
                  tooltip: 'Métricas de tesis y hardware',
                  icon: Icon(
                    _mostrarPanelMetricas ? Icons.tune : Icons.tune_outlined,
                    color: _mostrarPanelMetricas
                        ? const Color(0xFFB06B47)
                        : const Color(0xFF757575),
                    size: 24,
                  ),
                  onPressed: () => setState(
                      () => _mostrarPanelMetricas = !_mostrarPanelMetricas),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              esTutorial
                  ? 'Apunta a un objeto y toca el botón.'
                  : 'Mueve la cámara despacio hacia un objeto.',
              style: const TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Botón del modo tutorial: al tocarlo se analiza lo que ve la cámara.
  Widget _buildBotonCamaraTutorial() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22.0, top: 6.0),
      child: Semantics(
          button: true,
          label: 'Identificar el objeto',
          child: InkWell(
            onTap: _onTocarBotonCamaraTutorial,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                color: Color(0xFFDCE9EB), // Halo ring claro del mockup Figma
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: const Color(0xFF386673), // Círculo teal interior
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF386673).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.camera_alt_outlined,
                        color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
          )),
    );
  }

  void _onTocarBotonCamaraTutorial() {
    AccesibilidadService().feedbackInteraccion();
    if (_objetoDetectadoTutorial != null) {
      // Si ya hay un objeto enfocado en tutorial, reanudar visor para otra captura
      setState(() => _objetoDetectadoTutorial = null);
      return;
    }
    final candidato = _detectedItems.isNotEmpty
        ? _detectedItems.first
        : (_persistedItems.isNotEmpty ? _persistedItems.first : null);

    if (candidato != null) {
      setState(() => _objetoDetectadoTutorial = candidato);
      final item = candidato.item;
      final frase = item.frasePeticion ?? item.fraseApoyo ?? item.nombre;
      _speak(frase);
      return;
    }

    if (_dets.isNotEmpty) {
      for (final d in _dets) {
        if (d.cls >= 0 && d.cls < _labels.length) {
          final m = _catalogo.findPorEtiqueta(_labels[d.cls]);
          if (m != null) {
            final detItem =
                DetectedObjectItem(item: m, score: d.score, detection: d);
            setState(() => _objetoDetectadoTutorial = detItem);
            _speak(m.frasePeticion ?? m.fraseApoyo ?? m.nombre);
            return;
          }
        }
      }
    }

    // Ningún objeto del catálogo: pantalla «No lo pude ver bien» (Figma «Cámara · No reconocido»).
    setState(() => _noReconocidoTutorial = true);
    _speak('No lo pude ver bien. Probemos otra vez.');
  }

  /// Modo tutorial sin objeto reconocido: consejos y botón «Intentar otra vez».
  Widget _buildNoReconocido() {
    const teal = Color(0xFF3D6D7E);
    const texto = Color(0xFF3A3A3A);
    const textoSec = Color(0xFF6B6B66);
    const borde = Color(0xFFDDD6C9);
    const fuente = 'Atkinson Hyperlegible Next';
    Widget consejo(IconData icono, String t) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                    color: Color(0xFFDDE9EC), shape: BoxShape.circle),
                child: Icon(icono, color: teal, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(t,
                    style: const TextStyle(
                        fontFamily: fuente, fontSize: 13.5, color: texto)),
              ),
            ],
          ),
        );
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: [
            Semantics(
              excludeSemantics: true,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                    color: Color(0xFFF3E4DA), shape: BoxShape.circle),
                child: Center(
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFB06B47), width: 2.6),
                    ),
                    child: const Center(
                      child: Text('?',
                          style: TextStyle(
                              fontFamily: fuente,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB06B47))),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              liveRegion: true,
              child: const Text('No lo pude ver bien',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: fuente,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: texto)),
            ),
            const SizedBox(height: 8),
            const Text('Probemos otra vez.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: fuente, fontSize: 13, color: textoSec)),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borde, width: 1.5),
              ),
              child: Column(
                children: [
                  consejo(Icons.wb_sunny_outlined, 'Busca un lugar con luz'),
                  const Divider(
                      height: 1, thickness: 1, indent: 14, endIndent: 14, color: borde),
                  consejo(Icons.crop_square_rounded,
                      'Pon solo un objeto en el cuadro'),
                  const Divider(
                      height: 1, thickness: 1, indent: 14, endIndent: 14, color: borde),
                  consejo(Icons.smartphone_rounded, 'Mantén el teléfono quieto'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  AccesibilidadService().feedbackInteraccion();
                  setState(() => _noReconocidoTutorial = false);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Intentar otra vez',
                    style: TextStyle(
                        fontFamily: fuente,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Marco de guía para apuntar en modo tutorial antes de pulsar el botón
  Widget _buildGuiaApuntadoTutorial() {
    return Center(
      child: Container(
        width: 195,
        height: 195,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85),
            width: 3.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.center_focus_weak_rounded,
            color: Colors.white.withValues(alpha: 0.65),
            size: 46,
          ),
        ),
      ),
    );
  }

  /// Tarjeta inferior cuando hay un solo objeto.
  Widget _buildCardAbajo(DetectedObjectItem detItem) {
    final item = detItem.item;
    final frase = item.fraseApoyo ?? item.frasePeticion ?? item.nombre;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _speak(frase);
      },
      onDoubleTap: () => _mostrarResultadoFigma(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFDDD6C9), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2DDD5)),
              ),
              child: Image.asset(
                item.assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.category, size: 28, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.nombre,
                          style: const TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C2C2C),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2D6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(detItem.score * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB06B47),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    frase,
                    style: const TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF386673),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
                button: true,
                label: 'Escuchar',
                child: InkWell(
                  onTap: () => _speak(frase),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F5F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up_rounded,
                        color: Color(0xFF386673), size: 22),
                  ),
                )),
            const SizedBox(width: 6),
            Semantics(
                button: true,
                label: 'Ver en grande',
                child: InkWell(
                  onTap: () => _mostrarResultadoFigma(item),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF386673),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ),
                )),
            if (AccesibilidadService().tutorialCamara ||
                _objetoDetectadoTutorial != null) ...[
              const SizedBox(width: 6),
              // Botón cerrar para reanudar el visor en modo tutorial
              Semantics(
                  button: true,
                  label: 'Cerrar',
                  child: InkWell(
                    onTap: () =>
                        setState(() => _objetoDetectadoTutorial = null),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F5F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Color(0xFF757575), size: 20),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarResultadoFigma(CatalogoItem item) async {
    final nombreUpper = item.nombre.toUpperCase();
    _speak(item.frasePeticion ?? item.fraseApoyo ?? item.nombre);
    // «Ir a rutina» solo si el objeto es el del PRIMER paso de alguna rutina activa (US405, RF-03)
    final rutinasDelObjeto = await rutinasQueEmpiezanCon(item.assetPath);
    final tieneRutina = rutinasDelObjeto.isNotEmpty;
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + MediaQuery.of(ctx).viewPadding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Semantics(
                    button: true,
                    label: 'Volver',
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFDDD6C9), width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back,
                              color: Color(0xFF3A3A3A), size: 20),
                        ),
                      ),
                    )),
                const SizedBox(width: 14),
                const Text(
                  'Encontré esto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3A3A3A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDDD6C9), width: 2),
              ),
              child: Column(
                children: [
                  Image.asset(
                    item.assetPath,
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        size: 80,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nombreUpper,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3A3A3A),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (tieneRutina) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RutinasConObjetoPage(
                          nombreObjeto: item.nombre,
                          assetObjeto: item.assetPath,
                          rutinas: rutinasDelObjeto,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fact_check_rounded,
                      color: Colors.white, size: 20),
                  label: const Text('Ir a rutina',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF555555),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDDD6C9), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Buscar otro objeto',
                    style: TextStyle(
                        color: Color(0xFF3A3A3A), fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _statsCard() {
    String row(String n, LatencyStats s) =>
        '$n ${s.last.toStringAsFixed(0).padLeft(4)}  p50 ${s.p50.toStringAsFixed(0).padLeft(4)}  p95 ${s.p95.toStringAsFixed(0).padLeft(4)}';
    final ok = _e2e.count > 10 && _e2e.p95 < kObjetivoMs;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(8)),
      child: DefaultTextStyle(
        style: const TextStyle(
            color: Colors.white, fontFamily: 'monospace', fontSize: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_info?.delegateUsed ?? '-'} · ${_info?.inputShape ?? ''}'),
          Text(row('pre ', _pre)),
          Text(row('inf ', _inf)),
          Text(row('post', _post)),
          Text(row('e2e ', _e2e),
              style: TextStyle(
                  color: _e2e.count < 10
                      ? Colors.white
                      : (ok ? Colors.greenAccent : Colors.redAccent))),
          Text(
              '${_fps.toStringAsFixed(1)} fps · ${_dets.length} obj · n=${_e2e.all.length}'),
          if (!kReleaseMode && !kProfileMode)
            const Text('DEBUG: usa --profile para medir',
                style: TextStyle(color: Colors.orangeAccent)),
          if (_error != null)
            SizedBox(
                width: 260,
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent))),
        ]),
      ),
    );
  }

  /// Tamaño del frame girado (vertical) que ve el modelo: ancho = alto de la vista previa.
  Size? _tamanoFrame() {
    final ps = _cam?.value.previewSize;
    if (ps == null) return null;
    return Size(ps.height, ps.width);
  }

  /// Tarjetas de realidad aumentada: se dibujan encima del objeto (o debajo si no hay espacio),
  /// con un marco suave alrededor del objeto. AnimatedPositioned suaviza el movimiento entre frames.
  Widget _capaRealidadAumentada(Size vista) {
    final frame = _tamanoFrame();
    final hijos = <Widget>[];
    final dets = _detectedItems.take(_maxObjetosSimultaneos).toList();
    final ubicaciones = ubicarTarjetasRA(
        [for (final det in dets) cajaEnVista(det.detection, vista, frame)],
        vista);
    for (var i = 0; i < dets.length; i++) {
      final det = dets[i];
      final ubicacion = ubicaciones[i];
      if (ubicacion == null) continue;
      final caja = ubicacion.caja;
      final clave = det.item.clave;
      final enfocado = clave == _focusedClave;
      if (!ubicacion.grande) {
        hijos.add(AnimatedPositioned(
          key: ValueKey('marco_$clave'),
          duration: const Duration(milliseconds: 140),
          left: caja.left,
          top: caja.top,
          width: caja.width,
          height: caja.height,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: (enfocado ? const Color(0xFFE5A93C) : Colors.white)
                      .withValues(alpha: 0.85),
                  width: enfocado ? 3 : 2,
                ),
              ),
            ),
          ),
        ));
      }
      hijos.add(AnimatedPositioned(
        key: ValueKey('tarjeta_$clave'),
        duration: const Duration(milliseconds: 140),
        left: ubicacion.tarjeta.left,
        top: ubicacion.tarjeta.top,
        width: kAnchoTarjetaRA,
        height: kAltoTarjetaRA,
        child: _tarjetaRA(det, enfocado),
      ));
    }
    return Stack(clipBehavior: Clip.none, children: hijos);
  }

  Widget _tarjetaRA(DetectedObjectItem det, bool enfocado) {
    final item = det.item;
    return Semantics(
      button: true,
      label: '${item.nombre}. Toca para verlo en grande',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _focusedClave = item.clave);
          RegistroUsoService().registrar(RegistroUsoService.objeto, item.clave,
              etiqueta: item.nombre);
          _mostrarResultadoFigma(item);
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  enfocado ? const Color(0xFFE5A93C) : const Color(0xFFDDD6C9),
              width: enfocado ? 2.8 : 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 10, offset: Offset(0, 3))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  item.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.category, size: 26, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C2C2C),
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonMedicion(IconData icono, String texto, VoidCallback alTocar) {
    return OutlinedButton.icon(
      onPressed: alTocar,
      icon: Icon(icono, size: 18, color: Colors.white),
      label: Text(texto,
          style: const TextStyle(color: Colors.white, fontSize: 12.5)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white38),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<String>(
                value: _model,
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: [
                  for (final m in _models)
                    DropdownMenuItem(value: m, child: Text(m.split('/').last))
                ],
                onChanged: (v) {
                  _model = v;
                  _loadModel();
                },
              ),
              DropdownButton<String>(
                value: _delegate,
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: [
                  const DropdownMenuItem(value: 'cpu', child: Text('CPU')),
                  const DropdownMenuItem(value: 'gpu', child: Text('GPU')),
                  if (Platform.isAndroid)
                    const DropdownMenuItem(
                        value: 'nnapi', child: Text('NNAPI')),
                ],
                onChanged: (v) {
                  _delegate = v!;
                  _loadModel();
                },
              ),
              DropdownButton<int>(
                value: _threads,
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: [
                  for (final t in [1, 2, 4, 6])
                    DropdownMenuItem(value: t, child: Text('$t hilos'))
                ],
                onChanged: (v) {
                  _threads = v!;
                  _loadModel();
                },
              ),
              DropdownButton<int>(
                value: _maxObjetosSimultaneos,
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: const [
                  DropdownMenuItem(value: 2, child: Text('Máx 2 obj (TEA N2)')),
                  DropdownMenuItem(value: 3, child: Text('Máx 3 obj')),
                ],
                onChanged: (v) => setState(() => _maxObjetosSimultaneos = v!),
              ),
              DropdownButton<ResolutionPreset>(
                value: _resolution,
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: [
                  for (final r in [
                    ResolutionPreset.medium,
                    ResolutionPreset.high,
                    ResolutionPreset.veryHigh
                  ])
                    DropdownMenuItem(value: r, child: Text('cam ${r.name}')),
                ],
                onChanged: (v) {
                  _resolution = v!;
                  _resetStats();
                  _startCamera();
                },
              ),
            ]),
        Row(children: [
          const Text('umbral',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          Expanded(
            child: Slider(
              value: _threshold,
              min: 0.1,
              max: 0.9,
              divisions: 16,
              activeColor: const Color(0xFFE5A93C),
              label: _threshold.toStringAsFixed(2),
              onChanged: (v) => setState(() => _threshold = v),
            ),
          ),
          FilterChip(
            label: const Text('Estable', style: TextStyle(fontSize: 11)),
            tooltip:
                'Mostrar solo objetos vistos en $_minVistos de $_ventana frames',
            selected: _filtroTemporal,
            onSelected: (v) => setState(() => _filtroTemporal = v),
          ),
          const SizedBox(width: 4),
          FilterChip(
            label: const Text('Auto-voz', style: TextStyle(fontSize: 11)),
            selected: _autoVoice,
            onSelected: (v) => setState(() => _autoVoice = v),
          ),
          const SizedBox(width: 4),
          FilterChip(
            label: const Text('Cajas', style: TextStyle(fontSize: 11)),
            tooltip: 'Ver rectángulos detectados por YOLO',
            selected: _mostrarCajasDebug,
            onSelected: (v) => setState(() => _mostrarCajasDebug = v),
          ),
          IconButton(
            tooltip: 'Girar 90°',
            onPressed: () =>
                setState(() => _extraRotation = (_extraRotation + 90) % 360),
            icon: const Icon(Icons.rotate_90_degrees_cw, color: Colors.white70),
          ),
        ]),
        if (_benchText.isNotEmpty)
          Text(_benchText,
              style: const TextStyle(fontSize: 12, color: Colors.white)),
      ]),
    );
  }
}

class _BoxPainter extends CustomPainter {
  _BoxPainter(this.dets, this.labels, this.catalogo, this.frame);
  final List<Detection> dets;
  final List<String> labels;
  final CatalogoService catalogo;
  final Size? frame;

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in dets) {
      final rect = cajaEnVista(d, size, frame);
      final rawName =
          d.cls >= 0 && d.cls < labels.length ? labels[d.cls] : '#${d.cls}';
      if (rawName == '-') continue;
      final item = catalogo.findPorEtiqueta(rawName);
      if (item == null || !PerfilYolo26.claves.contains(item.clave)) continue;

      const strokeColor = Color(0xFFE5A93C);
      const bgColor = Color(0xFFB06B47);
      const textColor = Colors.white;

      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = strokeColor;
      canvas.drawRect(rect, stroke);

      final displayName = '${item.nombre} ($rawName)';
      final tp = TextPainter(
        text: TextSpan(
          text: ' $displayName ${(d.score * 100).toStringAsFixed(0)}% ',
          style: TextStyle(
              color: textColor,
              backgroundColor: bgColor,
              fontSize: 13,
              fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, rect.topLeft.translate(0, -tp.height));
    }
  }

  @override
  bool shouldRepaint(_BoxPainter old) => old.dets != dets;
}
