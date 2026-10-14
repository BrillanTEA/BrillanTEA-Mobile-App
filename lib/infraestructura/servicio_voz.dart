import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Servicio de Voz: único punto de acceso al motor de voz de Android (TextToSpeech, sin conexión).
/// Las pantallas y los servicios de dominio hablan a través de esta clase, no de flutter_tts.
class ServicioVoz {
  final FlutterTts _motor = FlutterTts();

  Future<dynamic> setLanguage(String idioma) => _motor.setLanguage(idioma);
  Future<dynamic> setSpeechRate(double velocidad) => _motor.setSpeechRate(velocidad);
  Future<dynamic> setVolume(double volumen) => _motor.setVolume(volumen);
  Future<dynamic> setPitch(double tono) => _motor.setPitch(tono);
  Future<dynamic> speak(String texto) => _motor.speak(texto);
  Future<dynamic> stop() => _motor.stop();
  void setCompletionHandler(VoidCallback alTerminar) => _motor.setCompletionHandler(alTerminar);
}
