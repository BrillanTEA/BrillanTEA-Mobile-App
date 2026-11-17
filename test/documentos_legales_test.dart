import 'package:brillantea/dominio/documentos_legales.dart';
import 'package:brillantea/infraestructura/bloqueo_service.dart';
import 'package:flutter_test/flutter_test.dart';

String _texto(DocumentoLegal d) => d.bloques
    .map((b) => [
          b.texto,
          ...b.tramos.map((t) => t.texto),
          ...b.lineas.expand((l) => l).map((t) => t.texto),
        ].join(' '))
    .join('\n');

void main() {
  final todo = _texto(terminosYCondiciones) + _texto(politicaDePrivacidad);

  group('Términos y privacidad (US901, US1007)', () {
    test('una sola versión en la cabecera, el pie y la aceptación', () {
      expect(versionDocumentosLegales, '1.0');
      for (final d in [terminosYCondiciones, politicaDePrivacidad]) {
        expect(d.version, startsWith('Versión $versionDocumentosLegales'));
        expect(_texto(d), contains('Fin del documento · Versión $versionDocumentosLegales'));
      }
    });

    test('describen la app real: una casilla y la sección Privacidad y datos', () {
      for (final viejo in ['tres casillas', 'tercera casilla', 'soporte@brillantea.net', 'Versión 2.2']) {
        expect(todo, isNot(contains(viejo)), reason: viejo);
      }
      expect(todo, contains('una casilla'));
      expect(todo, contains('Privacidad y datos → Retirar consentimiento'));
      expect(todo, contains('Privacidad y datos → Borrar los datos'));
    });

    test('el soporte usa los mismos correos en la app y en los documentos', () {
      expect(BloqueoService.correosSoporte, ['u201714765@upc.edu.pe', 'u202214784@upc.edu.pe']);
      for (final correo in BloqueoService.correosSoporte) {
        expect(todo, contains(correo));
      }
    });
  });
}
