import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../datos/base_datos.dart';
import '../infraestructura/servicio_voz.dart';

/// Preferencias de accesibilidad y estímulos (US1011).
/// Sonidos y lectura en voz alta vienen desactivados por defecto para no sobrecargar al niño (US1102).
class AccesibilidadService extends ChangeNotifier {
  static final AccesibilidadService _instance = AccesibilidadService._internal();
  factory AccesibilidadService() => _instance;
  AccesibilidadService._internal();

  // SQLite (catalogo.db): preferencia_accesibilidad y, para la fijación de pantalla, ajuste.
  final BaseDatos _bd = BaseDatos();

  int _tamanoTextoIndex = 1; // 0: 13 (Pequeño), 1: 15 (Normal), 2: 17 (Grande)
  bool _sonidosApp = false; // Desactivado por defecto (US1102)
  bool _vibracion = true;
  bool _leerVozAlta = false; // Desactivado por defecto (US1102)
  bool _tutorialCamara = true;
  bool _pantallaBloqueada = false;

  ServicioVoz? _tts;

  int get tamanoTextoIndex => _tamanoTextoIndex;
  bool get sonidosApp => _sonidosApp;
  bool get vibracion => _vibracion;
  bool get leerVozAlta => _leerVozAlta;
  bool get tutorialCamara => _tutorialCamara;
  bool get pantallaBloqueada => _pantallaBloqueada;

  /// Factor multiplicador aplicado al TextScaler global en MaterialApp
  /// Proporciones claramente diferenciadas para que la variación sea visible
  double get factorEscala {
    switch (_tamanoTextoIndex) {
      case 0:
        return 0.85; // Pequeño
      case 2:
        return 1.30; // Grande
      case 1:
      default:
        return 1.0; // Normal
    }
  }

  Future<void> init() async {
    try {
      final db = await _bd.db;
      final p = await db.query('preferencia_accesibilidad', where: 'id = 1');
      if (p.isNotEmpty) {
        final f = p.first;
        _tamanoTextoIndex = f['tamano_texto'] as int? ?? 1;
        _sonidosApp = f['sonidos'] == 1;
        _vibracion = f['vibracion'] != 0;
        _leerVozAlta = f['leer_voz_alta'] == 1;
        _tutorialCamara = f['tutorial_camara'] != 0;
      }
      final a = await db.query('ajuste', columns: ['pantalla_fijada'], where: 'id = 1');
      _pantallaBloqueada = a.isNotEmpty && a.first['pantalla_fijada'] == 1;
    } catch (_) {
      // Sin base de datos se usan los valores por defecto (US1102: baja estimulación)
    }
    notifyListeners();
  }

  Future<void> _guardar(String columna, Object valor) async {
    try {
      final db = await _bd.db;
      await db.update('preferencia_accesibilidad', {columna: valor}, where: 'id = 1');
    } catch (_) {}
  }

  Future<void> _initTts() async {
    if (_tts != null) return;
    try {
      _tts = ServicioVoz();
      await _tts?.setLanguage('es-ES');
      await _tts?.setSpeechRate(0.48);
      await _tts?.setVolume(1.0);
      await _tts?.setPitch(1.0);
    } catch (_) {}
  }

  /// Emite vibración háptica si la preferencia está activada
  void vibrar({bool fuerte = false}) {
    if (!_vibracion) return;
    if (fuerte) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  /// Emite sonido del sistema si la preferencia está activada
  void reproducirSonido() {
    if (!_sonidosApp) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Lee texto en voz alta si la preferencia está activada
  Future<void> hablar(String texto) async {
    if (!_leerVozAlta) return;
    try {
      await _initTts();
      await _tts?.stop();
      await _tts?.speak(texto);
    } catch (_) {}
  }

  /// Dispara feedback completo al tocar botones o elementos interactivos
  void feedbackInteraccion([String? textoParaLeer]) {
    vibrar();
    reproducirSonido();
    if (textoParaLeer != null && _leerVozAlta) {
      hablar(textoParaLeer);
    }
  }

  Future<void> setTamanoTextoIndex(int index) async {
    if (_tamanoTextoIndex == index) return;
    _tamanoTextoIndex = index;
    feedbackInteraccion();
    notifyListeners();
    await _guardar('tamano_texto', index);
  }

  Future<void> setSonidosApp(bool valor) async {
    _sonidosApp = valor;
    if (valor) {
      SystemSound.play(SystemSoundType.click);
    }
    notifyListeners();
    await _guardar('sonidos', valor ? 1 : 0);
  }

  Future<void> setVibracion(bool valor) async {
    _vibracion = valor;
    if (valor) {
      HapticFeedback.mediumImpact();
    }
    notifyListeners();
    await _guardar('vibracion', valor ? 1 : 0);
  }

  Future<void> setLeerVozAlta(bool valor) async {
    _leerVozAlta = valor;
    if (valor) {
      hablar('Lectura en voz alta activada');
    } else {
      _tts?.stop();
    }
    notifyListeners();
    await _guardar('leer_voz_alta', valor ? 1 : 0);
  }

  Future<void> setTutorialCamara(bool valor) async {
    _tutorialCamara = valor;
    feedbackInteraccion();
    notifyListeners();
    await _guardar('tutorial_camara', valor ? 1 : 0);
  }

  Future<void> setPantallaBloqueada(bool valor) async {
    _pantallaBloqueada = valor;
    feedbackInteraccion();
    notifyListeners();
    try {
      final db = await _bd.db;
      await db.update('ajuste', {'pantalla_fijada': valor ? 1 : 0}, where: 'id = 1');
    } catch (_) {}
  }
}
