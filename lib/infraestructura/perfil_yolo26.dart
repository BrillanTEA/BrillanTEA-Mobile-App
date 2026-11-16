/// Contrato fijo del candidato020; no implica calidad final ni validación clínica.
class PerfilYolo26 {
  static const asset = 'assets/models/yolo26_35_020_fp32.tflite';
  static const sha256Modelo =
      '1e9fad87a3157463e42efc5258bb0d6ecd5086fecd5405dc35807b7867cd3e7a';
  static const confianza = 0.25;
  static const iouNms = 0.45;
  static const maxDet = 300;
  static const claves = <String>[
    'cano',
    'jabon',
    'toalla',
    'pasta_dental',
    'cepillo_de_dientes',
    'vaso',
    'ropa',
    'medias',
    'zapatos',
    'cuaderno',
    'cartuchera',
    'lonchera',
    'pelota',
    'bloques_de_construccion',
    'caja_organizadora',
    'manzana',
    'platano',
    'naranja',
    'zanahoria',
    'sandwich',
    'torta',
    'cuchara',
    'tenedor',
    'tazon',
    'botella',
    'mesa',
    'silla',
    'cama',
    'sofa',
    'televisor',
    'reloj',
    'refrigeradora',
    'mochila',
    'peluche',
    'laptop',
  ];
  static void validarEtiquetas(List<String> labels) {
    if (labels.length != claves.length) {
      throw StateError('El candidato requiere 35 etiquetas');
    }
    for (var i = 0; i < claves.length; i++) {
      if (labels[i] != claves[i]) {
        throw StateError('Etiqueta incorrecta en ID $i');
      }
    }
  }

  static void validarTensores(
      List<int> entrada, List<int> salida, String tipo) {
    bool iguales(List<int> a, List<int> b) =>
        a.length == b.length &&
        List.generate(a.length, (i) => a[i] == b[i]).every((v) => v);
    if (!iguales(entrada, [1, 3, 640, 640]) ||
        !iguales(salida, [1, 39, 8400]) ||
        !tipo.contains('float32')) {
      throw StateError(
          'Los tensores no corresponden al candidato de 35 clases');
    }
  }

  static bool permite(int id, double score) =>
      id >= 0 &&
      id < claves.length &&
      score.isFinite &&
      score >= 0 &&
      score <= 1;
}
