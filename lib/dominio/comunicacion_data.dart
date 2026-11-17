// Contenido del módulo Comunicación (Figma: «Comunicación · Comer / Tomar / Jugar» y «Mi frase»).
// Las pantallas solo lo muestran; aquí se arma el texto de cada frase (US601, US603, US604).

const String _dir = 'assets/images/comunicacion';

/// Opción con pictograma. [fragmento] es lo que se agrega a la frase («agua», «jugar con la pelota»).
class OpcionComunicacion {
  final String id;
  final String nombre;
  final String asset;
  final String fragmento;

  const OpcionComunicacion({
    required this.id,
    required this.nombre,
    required this.asset,
    required this.fragmento,
  });
}

/// Pedido directo de «Pedir algo»: lo que dice la tarjeta y lo que se escucha.
class PedidoDirecto {
  final String nombre;
  final String frase;
  final String asset;

  const PedidoDirecto(this.nombre, this.frase, this.asset);
}

// ------------------------------------------------------------------ Pedir algo

const List<PedidoDirecto> pedidosComer = [
  PedidoDirecto('Pan', 'Quiero pan', '$_dir/pan.png'),
  PedidoDirecto('Manzana', 'Quiero manzana', '$_dir/manzana.png'),
  PedidoDirecto('Galleta', 'Quiero galleta', '$_dir/galleta.png'),
  PedidoDirecto('Plátano', 'Quiero plátano', '$_dir/platano.png'),
];

const List<PedidoDirecto> pedidosTomar = [
  PedidoDirecto('Agua', 'Quiero agua', '$_dir/agua.png'),
  PedidoDirecto('Leche', 'Quiero leche', '$_dir/leche.png'),
  PedidoDirecto('Jugo', 'Quiero jugo', '$_dir/jugo.png'),
  PedidoDirecto('Yogur', 'Quiero yogur', '$_dir/yogur.png'),
];

const List<PedidoDirecto> pedidosJugar = [
  PedidoDirecto('Pelota', 'Quiero la pelota', '$_dir/pelota.png'),
  PedidoDirecto('Bloques', 'Quiero los bloques', '$_dir/bloques.png'),
  PedidoDirecto('Pintar', 'Quiero pintar', '$_dir/pintar.png'),
  PedidoDirecto('Columpio', 'Quiero ir al columpio', '$_dir/columpio.png'),
];

// ------------------------------------------------------------------ Mi frase

/// Verbo del paso 1. Con «Me gusta» el sujeto cambia a «A mí» (US604).
class VerboFrase {
  final String clave;
  final String texto;
  final String sujeto;
  final String asset;

  const VerboFrase(this.clave, this.texto, this.sujeto, this.asset);
}

const List<VerboFrase> verbosFrase = [
  VerboFrase('quiero', 'Quiero', 'Yo', 'assets/images/frase_quiero.png'),
  VerboFrase('noquiero', 'No quiero', 'Yo', 'assets/images/frase_noquiero.png'),
  VerboFrase('necesito', 'Necesito', 'Yo', 'assets/images/frase_necesito.png'),
  VerboFrase('megusta', 'Me gusta', 'A mí', 'assets/images/frase_megusta.png'),
];

/// Categorías del paso 2. Baño y Ayuda completan la frase sin paso 3.
const List<OpcionComunicacion> categoriasFrase = [
  OpcionComunicacion(id: 'comer', nombre: 'Comer', asset: '$_dir/cat_comer.png', fragmento: 'comer'),
  OpcionComunicacion(id: 'tomar', nombre: 'Tomar', asset: '$_dir/cat_tomar.png', fragmento: 'tomar'),
  OpcionComunicacion(id: 'bano', nombre: 'Baño', asset: '$_dir/cat_bano.png', fragmento: 'ir al baño'),
  OpcionComunicacion(id: 'ayuda', nombre: 'Ayuda', asset: '$_dir/cat_ayuda.png', fragmento: 'ayuda'),
  OpcionComunicacion(id: 'jugar', nombre: 'Jugar', asset: '$_dir/cat_jugar.png', fragmento: 'jugar'),
  OpcionComunicacion(id: 'duele', nombre: 'Me duele', asset: '$_dir/cat_me_duele.png', fragmento: 'me duele'),
];

const Map<String, List<OpcionComunicacion>> objetosFrase = {
  'tomar': [
    OpcionComunicacion(id: 'agua', nombre: 'Agua', asset: '$_dir/agua.png', fragmento: 'agua'),
    OpcionComunicacion(id: 'jugo', nombre: 'Jugo', asset: '$_dir/jugo.png', fragmento: 'jugo'),
    OpcionComunicacion(id: 'leche', nombre: 'Leche', asset: '$_dir/leche.png', fragmento: 'leche'),
    OpcionComunicacion(id: 'chocolate', nombre: 'Chocolate', asset: '$_dir/chocolate.png', fragmento: 'chocolate'),
    OpcionComunicacion(id: 'te', nombre: 'Té', asset: '$_dir/te.png', fragmento: 'té'),
    OpcionComunicacion(id: 'yogur', nombre: 'Yogur', asset: '$_dir/yogur.png', fragmento: 'yogur'),
  ],
  'comer': [
    OpcionComunicacion(id: 'manzana', nombre: 'Manzana', asset: '$_dir/manzana.png', fragmento: 'manzana'),
    OpcionComunicacion(id: 'galleta', nombre: 'Galleta', asset: '$_dir/galleta.png', fragmento: 'galleta'),
    OpcionComunicacion(id: 'pan', nombre: 'Pan', asset: '$_dir/pan.png', fragmento: 'pan'),
    OpcionComunicacion(id: 'pollo', nombre: 'Pollo', asset: '$_dir/pollo.png', fragmento: 'pollo'),
    OpcionComunicacion(id: 'sandwich', nombre: 'Sándwich', asset: '$_dir/sandwich.png', fragmento: 'sándwich'),
    OpcionComunicacion(id: 'arroz', nombre: 'Arroz', asset: '$_dir/arroz.png', fragmento: 'arroz'),
  ],
  'jugar': [
    OpcionComunicacion(id: 'peluches', nombre: 'Peluches', asset: '$_dir/peluches.png', fragmento: 'jugar con peluches'),
    OpcionComunicacion(id: 'carros', nombre: 'Carros', asset: '$_dir/carros.png', fragmento: 'jugar con carros'),
    OpcionComunicacion(id: 'pelota', nombre: 'Pelota', asset: '$_dir/pelota.png', fragmento: 'jugar con la pelota'),
    OpcionComunicacion(id: 'bloques', nombre: 'Bloques', asset: '$_dir/bloques.png', fragmento: 'jugar con bloques'),
    OpcionComunicacion(id: 'dibujar', nombre: 'Dibujar', asset: '$_dir/dibujar.png', fragmento: 'dibujar'),
    OpcionComunicacion(id: 'columpio', nombre: 'Columpio', asset: '$_dir/columpio.png', fragmento: 'ir al columpio'),
  ],
  'duele': [
    OpcionComunicacion(id: 'cabeza', nombre: 'Cabeza', asset: '$_dir/cabeza.png', fragmento: 'la cabeza'),
    OpcionComunicacion(id: 'barriga', nombre: 'Barriga', asset: '$_dir/barriga.png', fragmento: 'la barriga'),
    OpcionComunicacion(id: 'cuerpo', nombre: 'Cuerpo', asset: '$_dir/cuerpo.png', fragmento: 'el cuerpo'),
    OpcionComunicacion(id: 'brazo', nombre: 'Brazo', asset: '$_dir/brazo.png', fragmento: 'el brazo'),
    OpcionComunicacion(id: 'pierna', nombre: 'Pierna', asset: '$_dir/pierna.png', fragmento: 'la pierna'),
    OpcionComunicacion(id: 'garganta', nombre: 'Garganta', asset: '$_dir/garganta.png', fragmento: 'la garganta'),
    OpcionComunicacion(id: 'oido', nombre: 'Oído', asset: '$_dir/oido.png', fragmento: 'el oído'),
    OpcionComunicacion(id: 'diente', nombre: 'Diente', asset: '$_dir/diente.png', fragmento: 'el diente'),
  ],
};

/// true si la categoría necesita el paso 3 (elegir un pictograma).
bool categoriaTienePaso3(String categoria) => objetosFrase.containsKey(categoria);

/// Pregunta del paso 2 según el verbo.
String preguntaPaso2(String verbo) {
  switch (verbo) {
    case 'megusta':
      return '¿Qué te gusta?';
    case 'noquiero':
      return '¿Qué no quieres?';
    case 'necesito':
      return '¿Qué necesitas?';
    default:
      return '¿Qué quieres decir?';
  }
}

/// Pregunta del paso 3 según el verbo y la categoría.
String preguntaPaso3(String verbo, String categoria) {
  if (categoria == 'duele') return '¿Dónde te duele?';
  final accion = categoria == 'tomar' ? 'tomar' : (categoria == 'comer' ? 'comer' : 'jugar');
  final inicio = categoria == 'jugar' ? '¿Con qué ' : '¿Qué ';
  switch (verbo) {
    case 'megusta':
      return '${inicio}te gusta $accion?';
    case 'noquiero':
      return '${inicio}no quieres $accion?';
    case 'necesito':
      return '${inicio}necesitas $accion?';
    default:
      return '${inicio}quieres $accion?';
  }
}

/// Frase completa que se lee en voz alta.
/// Ejemplos del Figma: «Yo quiero agua», «A mí me gusta jugar con peluches», «Yo no quiero pollo»,
/// «Yo necesito ayuda» y «A mí me duele la cabeza».
String armarFrase({
  required VerboFrase verbo,
  required OpcionComunicacion categoria,
  OpcionComunicacion? objeto,
}) {
  if (categoria.id == 'duele') {
    return 'A mí me duele ${objeto?.fragmento ?? 'algo'}';
  }
  final complemento = objeto?.fragmento ?? categoria.fragmento;
  return '${verbo.sujeto} ${verbo.texto.toLowerCase()} $complemento';
}
