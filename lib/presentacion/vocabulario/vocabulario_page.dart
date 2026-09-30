import 'package:flutter/material.dart';

import '../../dominio/accesibilidad_service.dart';
import '../../dominio/favoritos_service.dart';
import '../../dominio/registro_uso_service.dart';
import '../../infraestructura/servicio_voz.dart';

class ElementoVocabulario {
  final String id;
  final String nombre;
  final String silabas;
  final String fraseVoz;
  final String? assetPath;
  final String? simboloTexto;
  final Color? colorVisual;
  final IconData? iconoForma;

  const ElementoVocabulario({
    required this.id,
    required this.nombre,
    required this.silabas,
    required this.fraseVoz,
    this.assetPath,
    this.simboloTexto,
    this.colorVisual,
    this.iconoForma,
  });

  FavoritoItem toFavoritoItem(String categoriaNombre) {
    return FavoritoItem(
      id: id,
      nombre: nombre,
      modulo: 'Vocabulario',
      colorModuloValue: 0xFFA85D77,
      assetPath: assetPath,
      simboloTexto: simboloTexto,
      silabas: silabas,
      fraseVoz: fraseVoz,
    );
  }
}

class CategoriaVocabulario {
  final String id;
  final String nombre;
  final String subtitulo;
  final String assetBadge;
  final List<ElementoVocabulario> elementos;

  const CategoriaVocabulario({
    required this.id,
    required this.nombre,
    required this.subtitulo,
    required this.assetBadge,
    required this.elementos,
  });
}

/// Módulo Vocabulario: categorías, grilla de pictogramas y detalle ampliado.
class VocabularioPage extends StatefulWidget {
  final VoidCallback? onBack;

  const VocabularioPage({super.key, this.onBack});

  @override
  State<VocabularioPage> createState() => _VocabularioPageState();
}

class _VocabularioPageState extends State<VocabularioPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorEstrellaActiva = Color(0xFFF59E0B);

  final ServicioVoz _tts = ServicioVoz();
  final FavoritosService _favoritosService = FavoritosService();

  CategoriaVocabulario? _categoriaSeleccionada;
  int _indiceDetalle = -1; // -1: viendo grilla de categoría, >=0: viendo detalle ampliado

  final List<CategoriaVocabulario> _categorias = const [
    CategoriaVocabulario(
      id: 'animales',
      nombre: 'Animales',
      subtitulo: 'Toca un animal para verlo y escucharlo.',
      assetBadge: 'assets/images/cat_animales.png',
      elementos: [
        ElementoVocabulario(
          id: 'vocab_animales_perro',
          nombre: 'PERRO',
          silabas: 'PE · RRO',
          fraseVoz: 'Perro',
          assetPath: 'assets/images/vocab_perro.png',
        ),
        ElementoVocabulario(
          id: 'vocab_animales_gato',
          nombre: 'GATO',
          silabas: 'GA · TO',
          fraseVoz: 'Gato',
          assetPath: 'assets/images/vocab_gato.png',
        ),
        ElementoVocabulario(
          id: 'vocab_animales_pajaro',
          nombre: 'PÁJARO',
          silabas: 'PÁ · JA · RO',
          fraseVoz: 'Pájaro',
          assetPath: 'assets/images/vocab_pajaro.png',
        ),
        ElementoVocabulario(
          id: 'vocab_animales_pez',
          nombre: 'PEZ',
          silabas: 'PEZ',
          fraseVoz: 'Pez',
          assetPath: 'assets/images/vocab_pez.png',
        ),
        ElementoVocabulario(
          id: 'vocab_animales_tigre',
          nombre: 'TIGRE',
          silabas: 'TI · GRE',
          fraseVoz: 'Tigre',
          assetPath: 'assets/images/vocab_tigre.png',
        ),
        ElementoVocabulario(
          id: 'vocab_animales_elefante',
          nombre: 'ELEFANTE',
          silabas: 'E · LE · FAN · TE',
          fraseVoz: 'Elefante',
          assetPath: 'assets/images/vocab_elefante.png',
        ),
      ],
    ),
    CategoriaVocabulario(
      id: 'colores',
      nombre: 'Colores',
      subtitulo: 'Toca un color para verlo y escucharlo.',
      assetBadge: 'assets/images/cat_colores.png',
      elementos: [
        ElementoVocabulario(
          id: 'vocab_colores_rojo',
          nombre: 'ROJO',
          silabas: 'RO · JO',
          fraseVoz: 'Rojo',
          colorVisual: Color(0xFFE53935),
        ),
        ElementoVocabulario(
          id: 'vocab_colores_azul',
          nombre: 'AZUL',
          silabas: 'A · ZUL',
          fraseVoz: 'Azul',
          colorVisual: Color(0xFF1E88E5),
        ),
        ElementoVocabulario(
          id: 'vocab_colores_amarillo',
          nombre: 'AMARILLO',
          silabas: 'A · MA · RI · LLO',
          fraseVoz: 'Amarillo',
          colorVisual: Color(0xFFFDD835),
        ),
        ElementoVocabulario(
          id: 'vocab_colores_verde',
          nombre: 'VERDE',
          silabas: 'VER · DE',
          fraseVoz: 'Verde',
          colorVisual: Color(0xFF43A047),
        ),
        ElementoVocabulario(
          id: 'vocab_colores_naranja',
          nombre: 'NARANJA',
          silabas: 'NA · RAN · JA',
          fraseVoz: 'Naranja',
          colorVisual: Color(0xFFFB8C00),
        ),
        ElementoVocabulario(
          id: 'vocab_colores_morado',
          nombre: 'MORADO',
          silabas: 'MO · RA · DO',
          fraseVoz: 'Morado',
          colorVisual: Color(0xFF8E24AA),
        ),
      ],
    ),
    CategoriaVocabulario(
      id: 'numeros',
      nombre: 'Números',
      subtitulo: 'Toca un número para verlo y escucharlo.',
      assetBadge: 'assets/images/cat_numeros.png',
      elementos: [
        ElementoVocabulario(
          id: 'vocab_num_1',
          nombre: 'UNO',
          silabas: 'U · NO',
          fraseVoz: 'Número uno',
          simboloTexto: '1',
          colorVisual: Color(0xFFE53935),
        ),
        ElementoVocabulario(
          id: 'vocab_num_2',
          nombre: 'DOS',
          silabas: 'DOS',
          fraseVoz: 'Número dos',
          simboloTexto: '2',
          colorVisual: Color(0xFF1E88E5),
        ),
        ElementoVocabulario(
          id: 'vocab_num_3',
          nombre: 'TRES',
          silabas: 'TRES',
          fraseVoz: 'Número tres',
          simboloTexto: '3',
          colorVisual: Color(0xFF43A047),
        ),
        ElementoVocabulario(
          id: 'vocab_num_4',
          nombre: 'CUATRO',
          silabas: 'CUA · TRO',
          fraseVoz: 'Número cuatro',
          simboloTexto: '4',
          colorVisual: Color(0xFFFB8C00),
        ),
        ElementoVocabulario(
          id: 'vocab_num_5',
          nombre: 'CINCO',
          silabas: 'CIN · CO',
          fraseVoz: 'Número cinco',
          simboloTexto: '5',
          colorVisual: Color(0xFF8E24AA),
        ),
        ElementoVocabulario(
          id: 'vocab_num_6',
          nombre: 'SEIS',
          silabas: 'SEIS',
          fraseVoz: 'Número seis',
          simboloTexto: '6',
          colorVisual: Color(0xFF00ACC1),
        ),
      ],
    ),
    CategoriaVocabulario(
      id: 'letras',
      nombre: 'Letras',
      subtitulo: 'Toca una letra para verla y escucharla.',
      assetBadge: 'assets/images/cat_letras.png',
      elementos: [
        ElementoVocabulario(
          id: 'vocab_letra_a',
          nombre: 'LETRA A',
          silabas: 'A',
          fraseVoz: 'Letra A',
          simboloTexto: 'A',
          colorVisual: Color(0xFFE53935),
        ),
        ElementoVocabulario(
          id: 'vocab_letra_b',
          nombre: 'LETRA B',
          silabas: 'BE',
          fraseVoz: 'Letra B',
          simboloTexto: 'B',
          colorVisual: Color(0xFF1E88E5),
        ),
        ElementoVocabulario(
          id: 'vocab_letra_c',
          nombre: 'LETRA C',
          silabas: 'CE',
          fraseVoz: 'Letra C',
          simboloTexto: 'C',
          colorVisual: Color(0xFF43A047),
        ),
        ElementoVocabulario(
          id: 'vocab_letra_d',
          nombre: 'LETRA D',
          silabas: 'DE',
          fraseVoz: 'Letra D',
          simboloTexto: 'D',
          colorVisual: Color(0xFFFB8C00),
        ),
        ElementoVocabulario(
          id: 'vocab_letra_e',
          nombre: 'LETRA E',
          silabas: 'E',
          fraseVoz: 'Letra E',
          simboloTexto: 'E',
          colorVisual: Color(0xFF8E24AA),
        ),
        ElementoVocabulario(
          id: 'vocab_letra_m',
          nombre: 'LETRA M',
          silabas: 'E · ME',
          fraseVoz: 'Letra M',
          simboloTexto: 'M',
          colorVisual: Color(0xFF00ACC1),
        ),
      ],
    ),
    CategoriaVocabulario(
      id: 'frutas',
      nombre: 'Frutas',
      subtitulo: 'Toca una fruta para verla y escucharla.',
      assetBadge: 'assets/images/cat_frutas.png',
      elementos: [
        ElementoVocabulario(
          id: 'vocab_frutas_manzana',
          nombre: 'MANZANA',
          silabas: 'MAN · ZA · NA',
          fraseVoz: 'Manzana',
          assetPath: 'assets/pictogramas/manzana_2462.png',
        ),
        ElementoVocabulario(
          id: 'vocab_frutas_platano',
          nombre: 'PLÁTANO',
          silabas: 'PLÁ · TA · NO',
          fraseVoz: 'Plátano',
          assetPath: 'assets/pictogramas/platano_2530.png',
        ),
        ElementoVocabulario(
          id: 'vocab_frutas_naranja',
          nombre: 'NARANJA',
          silabas: 'NA · RAN · JA',
          fraseVoz: 'Naranja',
          assetPath: 'assets/pictogramas/naranja_2888.png',
        ),
        ElementoVocabulario(
          id: 'vocab_frutas_zanahoria',
          nombre: 'ZANAHORIA',
          silabas: 'ZA · NA · HO · RIA',
          fraseVoz: 'Zanahoria',
          assetPath: 'assets/pictogramas/zanahoria_2619.png',
        ),
        ElementoVocabulario(
          id: 'vocab_frutas_sandwich',
          nombre: 'SÁNDWICH',
          silabas: 'SÁND · WICH',
          fraseVoz: 'Sándwich',
          assetPath: 'assets/pictogramas/sandwich_3383.png',
        ),
        ElementoVocabulario(
          id: 'vocab_frutas_torta',
          nombre: 'TORTA',
          silabas: 'TOR · TA',
          fraseVoz: 'Torta',
          assetPath: 'assets/pictogramas/torta_2579.png',
        ),
      ],
    ),
    CategoriaVocabulario(
      id: 'formas',
      nombre: 'Formas',
      subtitulo: 'Toca una forma para verla y escucharla.',
      assetBadge: 'assets/images/cat_formas.png',
      elementos: [
        ElementoVocabulario(
          id: 'vocab_formas_circulo',
          nombre: 'CÍRCULO',
          silabas: 'CÍR · CU · LO',
          fraseVoz: 'Círculo',
          iconoForma: Icons.circle,
          colorVisual: Color(0xFFE53935),
        ),
        ElementoVocabulario(
          id: 'vocab_formas_cuadrado',
          nombre: 'CUADRADO',
          silabas: 'CUA · DRA · DO',
          fraseVoz: 'Cuadrado',
          iconoForma: Icons.square,
          colorVisual: Color(0xFF1E88E5),
        ),
        ElementoVocabulario(
          id: 'vocab_formas_triangulo',
          nombre: 'TRIÁNGULO',
          silabas: 'TRIÁN · GU · LO',
          fraseVoz: 'Triángulo',
          iconoForma: Icons.change_history_rounded,
          colorVisual: Color(0xFFFDD835),
        ),
        ElementoVocabulario(
          id: 'vocab_formas_estrella',
          nombre: 'ESTRELLA',
          silabas: 'ES · TRE · LLA',
          fraseVoz: 'Estrella',
          iconoForma: Icons.star_rounded,
          colorVisual: Color(0xFF43A047),
        ),
        ElementoVocabulario(
          id: 'vocab_formas_corazon',
          nombre: 'CORAZÓN',
          silabas: 'CO · RA · ZÓN',
          fraseVoz: 'Corazón',
          iconoForma: Icons.favorite_rounded,
          colorVisual: Color(0xFFE91E63),
        ),
        ElementoVocabulario(
          id: 'vocab_formas_rectangulo',
          nombre: 'RECTÁNGULO',
          silabas: 'REC · TÁN · GU · LO',
          fraseVoz: 'Rectángulo',
          iconoForma: Icons.crop_landscape_rounded,
          colorVisual: Color(0xFF00ACC1),
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _favoritosService.addListener(_onFavoritosChanged);
    _favoritosService.init();
  }

  @override
  void dispose() {
    _favoritosService.removeListener(_onFavoritosChanged);
    _tts.stop();
    super.dispose();
  }

  void _onFavoritosChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  void _hablar(String texto) async {
    AccesibilidadService().feedbackInteraccion();
    if (!AccesibilidadService().leerVozAlta) return;
    try {
      await _tts.stop();
      await _tts.speak(texto);
    } catch (_) {}
  }

  void _handleBack() {
    if (_indiceDetalle >= 0) {
      setState(() => _indiceDetalle = -1);
    } else if (_categoriaSeleccionada != null) {
      setState(() => _categoriaSeleccionada = null);
    } else if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_categoriaSeleccionada != null) {
      if (_indiceDetalle >= 0) {
        return _buildDetalleAmpliadoView();
      }
      return _buildGrillaCategoriaView();
    }
    return _buildCategoriasGrid();
  }

  // Vista 1: categorías
  Widget _buildCategoriasGrid() {
    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(button: true, label: 'Volver', child: InkWell(
                onTap: _handleBack,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorBorde, width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back, color: colorTextoPrincipal, size: 22),
                  ),
                ),
              )),
              const SizedBox(height: 16),

              const Text(
                'Vocabulario',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Elige qué quieres aprender.',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colorTextoSecundario,
                ),
              ),
              const SizedBox(height: 18),

              Expanded(
                child: GridView.builder(
                  itemCount: _categorias.length,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.88,
                  ),
                  itemBuilder: (context, index) {
                    final cat = _categorias[index];

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _categoriaSeleccionada = cat;
                          _indiceDetalle = -1;
                        });
                        _hablar(cat.nombre);
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colorTealPrimario, width: 2.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: Image.asset(
                                cat.assetBadge,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.category_rounded,
                                  size: 64,
                                  color: colorTealPrimario,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              cat.nombre,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Atkinson Hyperlegible Next',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colorTextoPrincipal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Vista 2: grilla de la categoría
  Widget _buildGrillaCategoriaView() {
    final cat = _categoriaSeleccionada!;

    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Semantics(button: true, label: 'Volver', child: InkWell(
                    onTap: _handleBack,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorBorde, width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back, color: colorTextoPrincipal, size: 22),
                      ),
                    ),
                  )),
                  const SizedBox(width: 14),
                  Text(
                    cat.nombre,
                    style: const TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: colorTextoPrincipal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                cat.subtitulo,
                style: const TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colorTextoSecundario,
                ),
              ),
              const SizedBox(height: 18),

              Expanded(
                child: GridView.builder(
                  itemCount: cat.elementos.length,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final item = cat.elementos[index];
                    final esFav = _favoritosService.esFavorito(item.id);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _indiceDetalle = index;
                        });
                        _hablar(item.fraseVoz);
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colorTealPrimario, width: 2.0),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    height: 80,
                                    child: _buildItemVisual(item, size: 76),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.nombre,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Atkinson Hyperlegible Next',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: colorTextoPrincipal,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Positioned(
                              top: -8,
                              right: -8,
                              child: Semantics(button: true, label: 'Marcar como favorito', child: InkWell(
                                onTap: () {
                                  _favoritosService.toggleFavorito(
                                    item.toFavoritoItem(cat.nombre),
                                  );
                                },
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: colorBorde, width: 1.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1F000000), // rgba(0, 0, 0, 0.12)
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      esFav ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: esFav ? colorEstrellaActiva : colorTextoSecundario,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              )),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Vista 3: detalle ampliado
  Widget _buildDetalleAmpliadoView() {
    final cat = _categoriaSeleccionada!;
    final item = cat.elementos[_indiceDetalle];
    final esFav = _favoritosService.esFavorito(item.id);
    final total = cat.elementos.length;
    final posicionTexto = '${_indiceDetalle + 1} de $total';

    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Semantics(button: true, label: 'Volver', child: InkWell(
                    onTap: _handleBack,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorBorde, width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back, color: colorTextoPrincipal, size: 22),
                      ),
                    ),
                  )),
                  const SizedBox(width: 14),
                  Text(
                    cat.nombre,
                    style: const TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: colorTextoPrincipal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 280),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colorTealPrimario, width: 2.0),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: -16,
                              right: -10,
                              child: Semantics(button: true, label: 'Marcar como favorito', child: InkWell(
                                onTap: () {
                                  _favoritosService.toggleFavorito(
                                    item.toFavoritoItem(cat.nombre),
                                  );
                                },
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: colorBorde, width: 1.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1F000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      esFav ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: esFav ? colorEstrellaActiva : colorTextoSecundario,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              )),
                            ),

                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 145,
                                  width: double.infinity,
                                  child: Center(
                                    child: _buildItemVisual(item, size: 130),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  item.nombre,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: colorTextoPrincipal,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Desglose silábico (ej. GA · TO)
                                Text(
                                  item.silabas,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 1.2,
                                    color: colorTextoSecundario,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        posicionTexto,
                        style: const TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: colorTextoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _favoritosService.registrarUso(item.id);
                    _hablar(item.fraseVoz);
                    RegistroUsoService().registrar(RegistroUsoService.pictograma, item.id, etiqueta: item.nombre);
                  },
                  icon: const Icon(Icons.volume_up_rounded, size: 22, color: Colors.white),
                  label: const Text(
                    'Escuchar',
                    style: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorTealPrimario,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _indiceDetalle > 0
                            ? () {
                                setState(() {
                                  _indiceDetalle -= 1;
                                });
                                final ant = cat.elementos[_indiceDetalle];
                                _hablar(ant.fraseVoz);
                              }
                            : null,
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          size: 24,
                          color: _indiceDetalle > 0 ? colorTealPrimario : colorTextoSecundario.withValues(alpha: 0.5),
                        ),
                        label: Text(
                          'Anterior',
                          style: TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _indiceDetalle > 0 ? colorTealPrimario : colorTextoSecundario.withValues(alpha: 0.5),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: colorBorde, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _indiceDetalle < total - 1
                            ? () {
                                setState(() {
                                  _indiceDetalle += 1;
                                });
                                final sig = cat.elementos[_indiceDetalle];
                                _hablar(sig.fraseVoz);
                              }
                            : null,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: colorBorde, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Siguiente',
                              style: TextStyle(
                                fontFamily: 'Atkinson Hyperlegible Next',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _indiceDetalle < total - 1
                                    ? colorTealPrimario
                                    : colorTextoSecundario.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 24,
                              color: _indiceDetalle < total - 1
                                  ? colorTealPrimario
                                  : colorTextoSecundario.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemVisual(ElementoVocabulario item, {required double size}) {
    if (item.assetPath != null) {
      return Image.asset(
        item.assetPath!,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => Icon(
          Icons.image_outlined,
          size: size * 0.7,
          color: colorTealPrimario,
        ),
      );
    }

    if (item.iconoForma != null) {
      return Icon(
        item.iconoForma,
        size: size * 0.85,
        color: item.colorVisual ?? colorTealPrimario,
      );
    }

    if (item.simboloTexto != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: (item.colorVisual ?? colorTealPrimario).withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: item.colorVisual ?? colorTealPrimario,
            width: 3.0,
          ),
        ),
        child: Center(
          child: Text(
            item.simboloTexto!,
            style: TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: size * 0.52,
              fontWeight: FontWeight.w800,
              color: item.colorVisual ?? colorTealPrimario,
            ),
          ),
        ),
      );
    }

    if (item.colorVisual != null) {
      return Container(
        width: size * 0.8,
        height: size * 0.8,
        decoration: BoxDecoration(
          color: item.colorVisual,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      );
    }

    return Icon(Icons.star_rounded, size: size * 0.7, color: colorTealPrimario);
  }
}
