import 'dart:io';

import 'package:flutter/services.dart';

/// Fijación de pantalla de Android (Screen Pinning) para que el niño no salga de la app (US905, US906).
class BloqueoService {
  static const MethodChannel _channel =
      MethodChannel('pe.brillantea.app/lock_task');

  /// Activa el modo de fijación de pantalla (Screen Pinning) en Android
  static Future<bool> startLockTask() async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('startLockTask');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Libera la fijación de pantalla en Android
  static Future<bool> stopLockTask() async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('stopLockTask');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Verifica si la app está actualmente fijada / en modo Lock Task
  static Future<bool> isLockTaskActive() async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isLockTaskActive');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Abre la pantalla de Seguridad de Android (para configurar PIN y fijar pantalla)
  static Future<bool> openSecuritySettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('openSecuritySettings');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Correos de soporte (RF-17): los de los Titulares, los mismos de los Términos y la Política.
  static const List<String> correosSoporte = ['u201714765@upc.edu.pe', 'u202214784@upc.edu.pe'];

  /// Abre la app de correo del celular con el destinatario y el asunto (Intent mailto).
  static Future<bool> abrirCorreoSoporte() async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('abrirCorreo', {
        'para': correosSoporte.join(','),
        'asunto': 'Brillantea: consulta de soporte',
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Abre la pantalla de Accesibilidad de los ajustes de Android
  static Future<bool> openAccessibilitySettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('openAccessibilitySettings');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
