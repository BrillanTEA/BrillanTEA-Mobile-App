/// Lo que pasó en la sesión de Calma en curso, para el «Aviso para el adulto» (US1303; Figma
/// «Calma · Aviso para el adulto»): la emoción elegida al empezar, los ejercicios que intentó el niño
/// o niña y cómo se siente ahora. Vive solo en memoria y se reinicia al entrar a Calma desde Inicio;
/// lo que se guarda en la base de datos sigue siendo el registro de uso de siempre.
class SesionCalma {
  SesionCalma._();

  static String? emocionId;
  static String? emocionNombre;
  static String? emocionAsset;
  static final List<String> intentos = [];

  /// 'mejor', 'igual' o 'peor' (respuesta a «¿Cómo te sientes ahora?»).
  static String? estadoActual;
  static DateTime? pidioAyuda;

  /// Empieza una sesión nueva. Si se llega desde Emociones, guarda la emoción elegida.
  static void iniciar({String? emocionId, String? emocionNombre, String? emocionAsset}) {
    SesionCalma.emocionId = emocionId;
    SesionCalma.emocionNombre = emocionNombre;
    SesionCalma.emocionAsset = emocionAsset;
    intentos.clear();
    estadoActual = null;
    pidioAyuda = null;
  }

  /// Agrega un ejercicio intentado («Respirar despacito», «Aprieta y suelta», «Descansar»).
  static void registrarIntento(String nombre) {
    if (!intentos.contains(nombre)) intentos.add(nombre);
  }

  static String get textoEstado {
    switch (estadoActual) {
      case 'mejor':
        return 'Se siente mejor';
      case 'peor':
        return 'Se siente peor';
      case 'igual':
        return 'Sigue igual';
      default:
        return 'Pidió ayuda';
    }
  }
}
