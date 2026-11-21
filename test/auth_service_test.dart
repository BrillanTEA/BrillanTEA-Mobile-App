import 'dart:convert';

import 'package:brillantea/datos/base_datos.dart';
import 'package:brillantea/dominio/auth_service.dart';
import 'package:brillantea/dominio/documentos_legales.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'soporte/entorno_prueba.dart';

// Perfil del Figma «Perfil del responsable · Completo».
const _adulto = PerfilAdulto(
  nombres: 'María',
  apellidoPaterno: 'Gómez',
  apellidoMaterno: '',
  diaNacimiento: '12',
  mesNacimiento: 'Mayo',
  anioNacimiento: '1991',
  ciudadNacimiento: 'Barranco',
  edad: '35',
  sexo: 'Femenino',
  parentesco: 'Mamá',
);
const _nino = PerfilNino(nombre: 'Mateo', edad: 8, avatar: 'nino');

void main() {
  final entorno = EntornoPrueba();
  final auth = AuthService();

  setUp(() => entorno.preparar());
  tearDown(() => entorno.limpiar());

  Future<Map<String, Object?>> ajuste() async =>
      (await (await BaseDatos().db).query('ajuste', where: 'id = 1')).single;

  group('Registro del primer uso (US902, US903)', () {
    test('guarda los perfiles y el PIN solo como hash PBKDF2 con sal', () async {
      expect(await auth.isConfigured(), isFalse);
      await auth.registrarPrimerUso(adulto: _adulto, pin: '2468', nino: _nino);

      expect(await auth.isConfigured(), isTrue);
      final adulto = await auth.getPerfilAdulto();
      expect(adulto!.nombres, 'María');
      expect(adulto.ciudadNacimiento, 'Barranco');
      expect(adulto.fechaNacimientoTexto, '12 de Mayo de 1991');
      final nino = await auth.getPerfilNino();
      expect(nino!.nombre, 'Mateo');
      expect(nino.edad, 8);

      final a = await ajuste();
      expect(a['pin_hash'], startsWith(r'pbkdf2$100000$'));
      expect(a['pin_hash'], isNot(contains('2468')));
      expect((a['pin_salt'] as String).length, greaterThanOrEqualTo(16));
    });

    test('actualiza los perfiles del niño y del adulto (US1004)', () async {
      await auth.actualizarPerfilAdulto(_adulto);
      await auth.actualizarPerfilNino(_nino);
      await auth.actualizarPerfilNino(const PerfilNino(nombre: 'Mati', edad: 9, avatar: 'nino'));
      expect((await auth.getPerfilNino())!.nombre, 'Mati');
      expect((await auth.getPerfilAdulto())!.parentesco, 'Mamá');
    });

    test('los perfiles pasan a fila y a JSON sin perder datos', () {
      expect(PerfilAdulto.fromFila(_adulto.toFila()).toJson(), _adulto.toJson());
      expect(PerfilAdulto.fromJson(_adulto.toJson()).nombreCompleto, 'María Gómez');
      expect(_adulto.nombresYApellidos, 'María Gómez');
      expect(PerfilAdulto.fromJson({'nombre': 'Ana'}).nombres, 'Ana');
      expect(PerfilNino.fromJson(_nino.toJson()).avatar, 'nino');
      expect(PerfilNino.fromFila(_nino.toFila()).edad, 8);
      expect(PerfilNino.fromJson(const {}).edad, 9);
    });
  });

  group('Acceso con PIN (US1001, US1002)', () {
    test('sin PIN registrado no se entra con ningún PIN', () async {
      expect(await auth.verificarPin('0000'), isFalse);
      expect(await auth.getFailedAttempts(), 0);
    });

    test('el PIN correcto entra y reinicia los intentos fallidos', () async {
      await auth.registrarPrimerUso(adulto: _adulto, pin: '2468', nino: _nino);
      expect(await auth.verificarPin('1111'), isFalse);
      expect(await auth.getFailedAttempts(), 1);
      expect(await auth.verificarPin('2468'), isTrue);
      expect(await auth.getFailedAttempts(), 0);
    });

    test('tras 3 PIN incorrectos se bloquea 5 minutos, aun con el PIN correcto', () async {
      await auth.registrarPrimerUso(adulto: _adulto, pin: '2468', nino: _nino);
      for (var i = 0; i < 3; i++) {
        expect(await auth.verificarPin('0000'), isFalse);
      }
      expect(await auth.isLocked(), isTrue);
      final segundos = await auth.getRemainingLockSeconds();
      expect(segundos, inInclusiveRange(290, 300));
      expect(await auth.verificarPin('2468'), isFalse);
    });

    test('al vencer el bloqueo se reinician los intentos y se puede entrar', () async {
      await auth.registrarPrimerUso(adulto: _adulto, pin: '2468', nino: _nino);
      final vencido = DateTime.now().subtract(const Duration(seconds: 1)).millisecondsSinceEpoch;
      await (await BaseDatos().db)
          .update('ajuste', {'bloqueado_hasta': vencido, 'intentos_pin': 3}, where: 'id = 1');
      expect(await auth.isLocked(), isFalse);
      expect(await auth.getFailedAttempts(), 0);
      expect(await auth.getRemainingLockSeconds(), 0);
      expect(await auth.verificarPin('2468'), isTrue);
    });

    test('un PIN guardado con el formato antiguo se convierte a PBKDF2', () async {
      const sal = 'sal-antigua';
      final antiguo = sha256.convert(utf8.encode('$sal:1357')).toString();
      await (await BaseDatos().db).update(
          'ajuste', {'pin_salt': sal, 'pin_hash': antiguo, 'configurada': 1},
          where: 'id = 1');
      expect(await auth.verificarPin('1357'), isTrue);
      expect((await ajuste())['pin_hash'], startsWith(r'pbkdf2$'));
      expect(await auth.verificarPin('1357'), isTrue);
    });

    test('cambiar el PIN invalida el anterior (US1006)', () async {
      await auth.registrarPrimerUso(adulto: _adulto, pin: '2468', nino: _nino);
      await auth.actualizarPin('9753');
      expect(await auth.verificarPin('9753'), isTrue);
      expect(await auth.verificarPin('2468'), isFalse);
    });
  });

  group('Recuperación del PIN (US1003)', () {
    test('acepta nombre, apellido y ciudad sin importar tildes, mayúsculas ni espacios', () async {
      await auth.actualizarPerfilAdulto(_adulto);
      final r = await auth.verificarRespuestasRecuperacionDetallado(
          nombre: '  maria ', apellido: 'GOMEZ', ciudad: 'barranco');
      expect(r.exito, isTrue);
      expect(r.intentosRestantes, 3);
      expect(
          await auth.verificarRespuestasRecuperacion(
              nombre: 'María', apellido: 'Gómez', ciudad: 'Barranco'),
          isTrue);
    });

    test('indica los intentos que quedan y bloquea al tercer intento fallido', () async {
      await auth.actualizarPerfilAdulto(_adulto);
      var r = await auth.verificarRespuestasRecuperacionDetallado(
          nombre: 'Marta', apellido: 'Gómez', ciudad: 'Lince');
      expect(r.exito, isFalse);
      expect(r.nombreValido, isFalse);
      expect(r.apellidoValido, isTrue);
      expect(r.ciudadValida, isFalse);
      expect(r.intentosRestantes, 2);
      expect(r.bloqueado, isFalse);

      r = await auth.verificarRespuestasRecuperacionDetallado(
          nombre: 'Marta', apellido: 'Gomes', ciudad: 'Lince');
      expect(r.intentosRestantes, 1);

      r = await auth.verificarRespuestasRecuperacionDetallado(
          nombre: 'Marta', apellido: 'Gomes', ciudad: 'Lince');
      expect(r.bloqueado, isTrue);
      expect(r.segundosBloqueo, 300);
      expect(r.intentosRestantes, 0);
      expect(await auth.isLocked(), isTrue);

      r = await auth.verificarRespuestasRecuperacionDetallado(
          nombre: 'María', apellido: 'Gómez', ciudad: 'Barranco');
      expect(r.exito, isFalse);
      expect(r.bloqueado, isTrue);
      expect(r.segundosBloqueo, greaterThan(0));
    });

    test('sin perfil del adulto ninguna respuesta es válida', () async {
      final r = await auth.verificarRespuestasRecuperacionDetallado(
          nombre: 'María', apellido: 'Gómez', ciudad: 'Barranco');
      expect(r.exito, isFalse);
      expect(r.nombreValido, isFalse);
      expect(r.intentosFallidos, 1);
    });
  });

  group('Consentimiento y borrado (US901, US1007)', () {
    test('aceptar guarda la fecha y la versión; retirarlo las borra', () async {
      await auth.setAcuerdoPrivacidadAceptado(true);
      expect(await auth.isAcuerdoPrivacidadAceptado(), isTrue);
      final registro = await auth.getRegistroAceptacion();
      expect(registro.version, versionDocumentosLegales);
      expect(registro.fecha, isNotNull);
      expect(await auth.getFechaAcuerdoPrivacidad(), isNotNull);

      await auth.setAcuerdoPrivacidadAceptado(false);
      expect(await auth.isAcuerdoPrivacidadAceptado(), isFalse);
      final sinRegistro = await auth.getRegistroAceptacion();
      expect(sinRegistro.fecha, isNull);
      expect(sinRegistro.version, isNull);
    });

    test('borrar los datos deja la app como recién instalada', () async {
      await auth.registrarPrimerUso(adulto: _adulto, pin: '2468', nino: _nino);
      await auth.setAcuerdoPrivacidadAceptado(true);
      final preferencias = await SharedPreferences.getInstance();
      await preferencias.setString('resto', 'dato');

      await auth.reiniciarTodo();

      expect(await auth.isConfigured(), isFalse);
      expect(await auth.isAcuerdoPrivacidadAceptado(), isFalse);
      expect(await auth.getPerfilAdulto(), isNull);
      expect(await auth.getPerfilNino(), isNull);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    });
  });
}
