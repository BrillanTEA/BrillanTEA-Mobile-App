import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../datos/base_datos.dart';
import 'favoritos_service.dart';
import 'reporte_service.dart';

class PerfilAdulto {
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String diaNacimiento;
  final String mesNacimiento;
  final String anioNacimiento;
  /// Ciudad o distrito donde vive el adulto (lista del registro). La columna conserva el nombre
  /// ciudad_nacimiento para no migrar la base de datos.
  final String ciudadNacimiento;
  final String edad;
  final String sexo; // 'Femenino', 'Masculino', 'Otro'
  final String parentesco; // 'Mamá', 'Papá', 'Abuela o abuelo', etc.

  const PerfilAdulto({
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.diaNacimiento,
    required this.mesNacimiento,
    required this.anioNacimiento,
    required this.ciudadNacimiento,
    required this.edad,
    required this.sexo,
    required this.parentesco,
  });

  String get nombreCompleto => '$nombres $apellidoPaterno $apellidoMaterno'.trim();

  String get nombresYApellidos => nombreCompleto;

  String get fechaNacimientoTexto => '$diaNacimiento de $mesNacimiento de $anioNacimiento';

  Map<String, dynamic> toJson() => {
        'nombres': nombres,
        'apellidoPaterno': apellidoPaterno,
        'apellidoMaterno': apellidoMaterno,
        'diaNacimiento': diaNacimiento,
        'mesNacimiento': mesNacimiento,
        'anioNacimiento': anioNacimiento,
        'ciudadNacimiento': ciudadNacimiento,
        'edad': edad,
        'sexo': sexo,
        'parentesco': parentesco,
      };

  /// Fila de la tabla perfil_adulto (SQLite).
  Map<String, Object?> toFila() => {
        'id': 1,
        'nombres': nombres,
        'apellido_paterno': apellidoPaterno,
        'apellido_materno': apellidoMaterno,
        'dia_nacimiento': diaNacimiento,
        'mes_nacimiento': mesNacimiento,
        'anio_nacimiento': anioNacimiento,
        'ciudad_nacimiento': ciudadNacimiento,
        'edad': edad,
        'sexo': sexo,
        'parentesco': parentesco,
      };

  factory PerfilAdulto.fromFila(Map<String, Object?> f) => PerfilAdulto(
        nombres: f['nombres'] as String? ?? '',
        apellidoPaterno: f['apellido_paterno'] as String? ?? '',
        apellidoMaterno: f['apellido_materno'] as String? ?? '',
        diaNacimiento: f['dia_nacimiento'] as String? ?? '',
        mesNacimiento: f['mes_nacimiento'] as String? ?? 'Abril',
        anioNacimiento: f['anio_nacimiento'] as String? ?? '',
        ciudadNacimiento: f['ciudad_nacimiento'] as String? ?? '',
        edad: f['edad'] as String? ?? '',
        sexo: f['sexo'] as String? ?? 'Femenino',
        parentesco: f['parentesco'] as String? ?? 'Madre',
      );

  factory PerfilAdulto.fromJson(Map<String, dynamic> j) => PerfilAdulto(
        nombres: j['nombres'] ?? j['nombre'] ?? '',
        apellidoPaterno: j['apellidoPaterno'] ?? '',
        apellidoMaterno: j['apellidoMaterno'] ?? '',
        diaNacimiento: j['diaNacimiento'] ?? '',
        mesNacimiento: j['mesNacimiento'] ?? 'Abril',
        anioNacimiento: j['anioNacimiento'] ?? '',
        ciudadNacimiento: j['ciudadNacimiento'] ?? '',
        edad: j['edad'] ?? '',
        sexo: j['sexo'] ?? 'Femenino',
        parentesco: j['parentesco'] ?? 'Madre',
      );
}

class PerfilNino {
  final String nombre; // Primer nombre o apodo
  final int edad; // 6 a 10 años
  final String avatar; // 'nino' o 'nina'

  const PerfilNino({
    required this.nombre,
    required this.edad,
    required this.avatar,
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'edad': edad,
        'avatar': avatar,
      };

  /// Fila de la tabla perfil_nino (SQLite).
  Map<String, Object?> toFila() => {'id': 1, 'nombre': nombre, 'edad': edad, 'avatar': avatar};

  factory PerfilNino.fromFila(Map<String, Object?> f) => PerfilNino(
        nombre: f['nombre'] as String? ?? '',
        edad: f['edad'] as int? ?? 9,
        avatar: f['avatar'] as String? ?? 'nino',
      );

  factory PerfilNino.fromJson(Map<String, dynamic> j) => PerfilNino(
        nombre: j['nombre'] ?? '',
        edad: j['edad'] ?? 9,
        avatar: j['avatar'] ?? 'nino',
      );
}

class ResultadoRecuperacion {
  final bool exito;
  final bool nombreValido;
  final bool apellidoValido;
  final bool ciudadValida;
  final int intentosFallidos;
  final int intentosRestantes;
  final bool bloqueado;
  final int segundosBloqueo;

  const ResultadoRecuperacion({
    required this.exito,
    required this.nombreValido,
    required this.apellidoValido,
    required this.ciudadValida,
    required this.intentosFallidos,
    required this.intentosRestantes,
    required this.bloqueado,
    required this.segundosBloqueo,
  });
}

/// Servicio de Autenticación, PIN Local y Perfiles
/// Implementa los requerimientos RF-06, OWASP MASVS y Ley N.° 29733:
/// - 100% Offline (sin servidores externos ni almacenamiento en la nube)
/// - Datos en SQLite (catalogo.db): perfil_adulto, perfil_nino y ajuste (PIN, intentos, bloqueo)
/// - PIN guardado con PBKDF2-HMAC-SHA256 (100 000 iteraciones) y sal aleatoria de 16 bytes (OWASP MASVS-CRYPTO). Los PIN guardados con el formato antiguo (un SHA-256) se convierten solos
///   a PBKDF2 la próxima vez que el adulto ingresa bien su PIN.
/// - Control de 3 intentos fallidos con bloqueo de 5 minutos
/// - Recuperación mediante las 3 preguntas estables del adulto (fecha, apellido materno, ciudad)
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final BaseDatos _bd = BaseDatos();

  Future<Map<String, Object?>> _ajuste() async {
    final db = await _bd.db;
    final filas = await db.query('ajuste', where: 'id = 1');
    return filas.isEmpty ? <String, Object?>{} : filas.first;
  }

  Future<void> _guardarAjuste(Map<String, Object?> valores) async {
    final db = await _bd.db;
    await db.update('ajuste', valores, where: 'id = 1');
  }

  static int _entero(Object? v) => v is int ? v : 0;

  Future<bool> isAcuerdoPrivacidadAceptado() async => (await _ajuste())['acuerdo_privacidad'] == 1;

  Future<void> setAcuerdoPrivacidadAceptado(bool valor) async {
    await _guardarAjuste({
      'acuerdo_privacidad': valor ? 1 : 0,
      'acuerdo_fecha': valor ? DateTime.now().toIso8601String() : null,
    });
  }

  Future<String?> getFechaAcuerdoPrivacidad() async => (await _ajuste())['acuerdo_fecha'] as String?;

  Future<bool> isConfigured() async => (await _ajuste())['configurada'] == 1;

  Future<PerfilAdulto?> getPerfilAdulto() async {
    final db = await _bd.db;
    final filas = await db.query('perfil_adulto', where: 'id = 1');
    return filas.isEmpty ? null : PerfilAdulto.fromFila(filas.first);
  }

  Future<PerfilNino?> getPerfilNino() async {
    final db = await _bd.db;
    final filas = await db.query('perfil_nino', where: 'id = 1');
    return filas.isEmpty ? null : PerfilNino.fromFila(filas.first);
  }

  String _generarSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64Encode(bytes);
  }

  /// Formato antiguo (un solo SHA-256). Solo se usa para verificar PIN guardados antes de PBKDF2.
  String _hashearPin(String pin, String salt) {
    final raw = '$salt:$pin';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  static const int _iteraciones = 100000;

  /// PBKDF2-HMAC-SHA256 (RFC 8018), 32 bytes de salida.
  static List<int> _pbkdf2(List<int> clave, List<int> sal, int iteraciones) {
    final hmac = Hmac(sha256, clave);
    final u0 = hmac.convert([...sal, 0, 0, 0, 1]).bytes;
    var u = u0;
    final t = List<int>.from(u0);
    for (var k = 1; k < iteraciones; k++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    return t;
  }

  /// Calcula el hash en otro hilo (Isolate) para que la pantalla no se congele.
  static Future<String> _hashearPinSeguro(String pin, String salt, {int iteraciones = _iteraciones}) async {
    final h = await Isolate.run(() => _pbkdf2(utf8.encode(pin), utf8.encode(salt), iteraciones));
    return 'pbkdf2\$$iteraciones\$${base64Encode(h)}';
  }

  static bool _igual(String a, String b) {
    if (a.length != b.length) return false;
    var dif = 0;
    for (var i = 0; i < a.length; i++) {
      dif |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return dif == 0;
  }

  Future<bool> _pinCoincide(String pin, String salt, String guardado) async {
    if (guardado.startsWith('pbkdf2\$')) {
      final partes = guardado.split('\$');
      final iter = partes.length == 3 ? int.tryParse(partes[1]) ?? _iteraciones : _iteraciones;
      return _igual(await _hashearPinSeguro(pin, salt, iteraciones: iter), guardado);
    }
    return _igual(_hashearPin(pin, salt), guardado); // formato antiguo
  }

  Future<void> registrarPrimerUso({
    required PerfilAdulto adulto,
    required String pin,
    required PerfilNino nino,
  }) async {
    final salt = _generarSalt();
    final hash = await _hashearPinSeguro(pin, salt);
    final db = await _bd.db;
    await db.transaction((txn) async {
      await txn.insert('perfil_adulto', adulto.toFila(), conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('perfil_nino', nino.toFila(), conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.update(
        'ajuste',
        {
          'pin_salt': salt,
          'pin_hash': hash,
          'configurada': 1,
          'intentos_pin': 0,
          'intentos_recuperacion': 0,
          'bloqueado_hasta': null,
        },
        where: 'id = 1',
      );
    });
  }

  Future<void> actualizarPerfilNino(PerfilNino nino) async {
    final db = await _bd.db;
    await db.insert('perfil_nino', nino.toFila(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> actualizarPerfilAdulto(PerfilAdulto adulto) async {
    final db = await _bd.db;
    await db.insert('perfil_adulto', adulto.toFila(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> isLocked() async {
    final lockedMillis = (await _ajuste())['bloqueado_hasta'] as int?;
    if (lockedMillis == null) return false;

    final lockedUntil = DateTime.fromMillisecondsSinceEpoch(lockedMillis);
    if (DateTime.now().isBefore(lockedUntil)) {
      return true;
    } else {
      await _guardarAjuste({'bloqueado_hasta': null, 'intentos_pin': 0, 'intentos_recuperacion': 0});
      return false;
    }
  }

  Future<int> getRemainingLockSeconds() async {
    final lockedMillis = (await _ajuste())['bloqueado_hasta'] as int?;
    if (lockedMillis == null) return 0;

    final lockedUntil = DateTime.fromMillisecondsSinceEpoch(lockedMillis);
    final diff = lockedUntil.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  Future<int> getFailedAttempts() async => _entero((await _ajuste())['intentos_pin']);

  Future<bool> verificarPin(String pinIngresado) async {
    if (await isLocked()) {
      return false;
    }

    final aj = await _ajuste();
    final salt = aj['pin_salt'] as String?;
    final hashGuardado = aj['pin_hash'] as String?;

    if (salt == null || hashGuardado == null) {
      return false; // sin PIN registrado no se entra: no existe un PIN por defecto
    }

    if (await _pinCoincide(pinIngresado, salt, hashGuardado)) {
      final cambios = <String, Object?>{'intentos_pin': 0, 'bloqueado_hasta': null};
      if (!hashGuardado.startsWith('pbkdf2\$')) {
        cambios['pin_hash'] = await _hashearPinSeguro(pinIngresado, salt); // migra al formato PBKDF2
      }
      await _guardarAjuste(cambios);
      return true;
    } else {
      final fallos = _entero(aj['intentos_pin']) + 1;
      final cambios = <String, Object?>{'intentos_pin': fallos};
      if (fallos >= 3) {
        // Bloqueo de 5 minutos según OWASP MASVS y RF-06
        cambios['bloqueado_hasta'] = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
      }
      await _guardarAjuste(cambios);
      return false;
    }
  }

  static String _normalizarTexto(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâã]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöôõ]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  /// Recuperación del PIN (US1003): tres datos del perfil del adulto, insensibles a tildes,
  /// mayúsculas y espacios:
  /// 1. Nombre
  /// 2. Apellido
  /// 3. Ciudad o distrito donde vive
  Future<ResultadoRecuperacion> verificarRespuestasRecuperacionDetallado({
    required String nombre,
    required String apellido,
    required String ciudad,
  }) async {
    if (await isLocked()) {
      final segs = await getRemainingLockSeconds();
      return ResultadoRecuperacion(
        exito: false,
        nombreValido: false,
        apellidoValido: false,
        ciudadValida: false,
        intentosFallidos: 3,
        intentosRestantes: 0,
        bloqueado: true,
        segundosBloqueo: segs,
      );
    }

    final adulto = await getPerfilAdulto();

    final normNombre = _normalizarTexto(nombre);
    final normApellido = _normalizarTexto(apellido);
    final normCiudad = _normalizarTexto(ciudad);

    bool nombreOk = false;
    bool apellidoOk = false;
    bool ciudadOk = false;

    if (adulto != null) {
      final nombreRegistrado = _normalizarTexto(adulto.nombres);
      final apellidoRegistrado = _normalizarTexto(adulto.apellidoPaterno);
      final ciudadRegistrada = _normalizarTexto(adulto.ciudadNacimiento);

      nombreOk = normNombre.isNotEmpty && normNombre == nombreRegistrado;
      apellidoOk = normApellido.isNotEmpty && normApellido == apellidoRegistrado;
      ciudadOk = normCiudad.isNotEmpty && normCiudad == ciudadRegistrada;
    }

    if (nombreOk && apellidoOk && ciudadOk) {
      await _guardarAjuste({'intentos_recuperacion': 0, 'intentos_pin': 0, 'bloqueado_hasta': null});
      return const ResultadoRecuperacion(
        exito: true,
        nombreValido: true,
        apellidoValido: true,
        ciudadValida: true,
        intentosFallidos: 0,
        intentosRestantes: 3,
        bloqueado: false,
        segundosBloqueo: 0,
      );
    } else {
      // Cada intento fallido suma, independientemente de si los datos cambiaron o son iguales
      final fallos = _entero((await _ajuste())['intentos_recuperacion']) + 1;
      final cambios = <String, Object?>{'intentos_recuperacion': fallos};

      bool bloqueado = false;
      int segs = 0;
      if (fallos >= 3) {
        bloqueado = true;
        cambios['bloqueado_hasta'] = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
        segs = 300;
      }
      await _guardarAjuste(cambios);

      final restantes = (3 - fallos).clamp(0, 3);

      return ResultadoRecuperacion(
        exito: false,
        nombreValido: nombreOk,
        apellidoValido: apellidoOk,
        ciudadValida: ciudadOk,
        intentosFallidos: fallos,
        intentosRestantes: restantes,
        bloqueado: bloqueado,
        segundosBloqueo: segs,
      );
    }
  }

  Future<bool> verificarRespuestasRecuperacion({
    required String fechaOAnioNacimiento,
    required String apellidoMaterno,
    required String ciudadNacimiento,
  }) async {
    final res = await verificarRespuestasRecuperacionDetallado(
      anioNacimiento: fechaOAnioNacimiento,
      apellidoMaterno: apellidoMaterno,
      ciudadNacimiento: ciudadNacimiento,
    );
    return res.exito;
  }

  Future<void> actualizarPin(String nuevoPin) async {
    final salt = _generarSalt();
    final hash = await _hashearPinSeguro(nuevoPin, salt);
    await _guardarAjuste({
      'pin_salt': salt,
      'pin_hash': hash,
      'intentos_pin': 0,
      'intentos_recuperacion': 0,
      'bloqueado_hasta': null,
    });
  }

  /// Borra todos los datos de la aplicación: la base SQLite completa (perfiles, PIN, configuración,
  /// favoritos, progreso, registro de uso y notas), cualquier resto en SharedPreferences
  /// y las copias temporales del reporte PDF.
  Future<void> reiniciarTodo() async {
    await ReporteService.borrarTodos();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.clear();
    } catch (_) {}
    await _bd.borrarTodo();
    FavoritosService().limpiarMemoria();
  }
}
