import 'dart:io';

import 'package:flutter/services.dart';

/// Fijación de pantalla de Android (Screen Pinning) para que el niño no salga de la app (US905, US906).
class BloqueoService {
  static const MethodChannel _channel =
      MethodChannel('pe.tesis.tea.spike_edge_ai/lock_task');

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

  /// Correo de soporte (RF-17). Cambiarlo aquí cuando haya un correo oficial del proyecto.
  static const String correoSoporte = 'ricardobarrutia99@gmail.com';

  /// Abre la app de correo del celular con el destinatario y el asunto (Intent mailto).
  static Future<bool> abrirCorreoSoporte() async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('abrirCorreo', {
        'para': correoSoporte,
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
