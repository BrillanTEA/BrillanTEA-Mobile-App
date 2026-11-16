import 'package:flutter/services.dart';

/// Formateador que elimina tildes, diéresis y acentos en tiempo real,
/// convirtiendo vocales acentuadas en vocales estándar (á -> a, É -> E, etc.)
/// y eliminando la tecla muerta del acento (´, `, ^, ~, ¨).
/// Preserva la 'ñ' y 'Ñ'.
class SinTildesFormatter extends TextInputFormatter {
  static const Map<String, String> _mapaTildes = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'Á': 'A', 'À': 'A', 'Ä': 'A', 'Â': 'A', 'Ã': 'A', 'Å': 'A',
    'É': 'E', 'È': 'E', 'Ë': 'E', 'Ê': 'E',
    'Í': 'I', 'Ì': 'I', 'Ï': 'I', 'Î': 'I',
    'Ó': 'O', 'Ò': 'O', 'Ö': 'O', 'Ô': 'O', 'Õ': 'O',
    'Ú': 'U', 'Ù': 'U', 'Ü': 'U', 'Û': 'U',
    'ý': 'y', 'ÿ': 'y', 'Ý': 'Y', 'ç': 'c', 'Ç': 'C',
    '´': '', '`': '', '¨': '', '^': '', '~': '',
  };

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    for (final entry in _mapaTildes.entries) {
      if (text.contains(entry.key)) {
        text = text.replaceAll(entry.key, entry.value);
      }
    }
    // Eliminar caracteres combinatorios de acento (Unicode combining diacritical marks)
    text = text.replaceAll(RegExp(r'[\u0300-\u036f]'), '');

    if (text == newValue.text) {
      return newValue;
    }

    final int diff = newValue.text.length - text.length;
    final int newOffset = (newValue.selection.end - diff).clamp(0, text.length);

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: newOffset),
      composing: TextRange.empty,
    );
  }

  /// Limpia cualquier tilde o marca diacrítica de un texto de forma estática
  static String limpiar(String s) {
    String text = s;
    for (final entry in _mapaTildes.entries) {
      if (text.contains(entry.key)) {
        text = text.replaceAll(entry.key, entry.value);
      }
    }
    return text.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
  }
}

/// Función global conveniente para limpiar tildes de cualquier texto
String limpiarTildes(String s) => SinTildesFormatter.limpiar(s);
