import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brillantea/presentacion/comun/formatters.dart';

void main() {
  group('SinTildesFormatter tests', () {
    final formatter = SinTildesFormatter();

    test('Normaliza vocales con tildes agudas minúsculas y mayúsculas', () {
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: 'María Gómez Raúl Érika Óscar',
          selection: TextSelection.collapsed(offset: 28),
        ),
      );
      expect(value.text, 'Maria Gomez Raul Erika Oscar');
    });

    test('Elimina tecla muerta de tildes y diéresis solas', () {
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '´',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      expect(value.text, '');
      expect(value.selection.baseOffset, 0);
    });

    test('Conserva la letra ñ y Ñ sin alterarlas', () {
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: 'Nuñez Castaño BAÑOS',
          selection: TextSelection.collapsed(offset: 19),
        ),
      );
      expect(value.text, 'Nunez Castano BANOS'.replaceAll('Nunez', 'Nuñez').replaceAll('Castano', 'Castaño').replaceAll('BANOS', 'BAÑOS'));
      expect(value.text, 'Nuñez Castaño BAÑOS');
    });

    test('Normaliza marcas diacríticas combinadas (Unicode combining marks)', () {
      // 'a' followed by combining acute accent U+0301
      const combining = 'Ma\u0301ria';
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: combining,
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      expect(value.text, 'Maria');
    });

    test('Funciona en conjunto con FilteringTextInputFormatter.allow', () {
      final formatters = [
        SinTildesFormatter(),
        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZñÑ\s]")),
      ];

      TextEditingValue current = TextEditingValue.empty;
      // Simulamos escribir 'M', 'a', 'r', 'í', 'a'
      for (final char in ['M', 'a', 'r', 'í', 'a']) {
        final next = TextEditingValue(
          text: current.text + char,
          selection: TextSelection.collapsed(offset: current.text.length + 1),
        );
        var updated = next;
        for (final f in formatters) {
          updated = f.formatEditUpdate(current, updated);
        }
        current = updated;
      }
      expect(current.text, 'Maria');
    });
  });
}
