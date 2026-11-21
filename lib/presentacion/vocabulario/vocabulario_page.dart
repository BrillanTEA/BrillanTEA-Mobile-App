import 'package:flutter/material.dart';

import '../../dominio/accesibilidad_service.dart';
import '../../dominio/favoritos_service.dart';
import '../../dominio/registro_uso_service.dart';
import '../../infraestructura/servicio_voz.dart';
import 'vocabulario_catalogo.dart';
import 'vocabulario_modelo.dart';

/// Módulo Vocabulario (US701, US702, US705): categorías, grilla con buscador y detalle ampliado.
/// El contenido está en vocabulario_catalogo.dart.
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

  final List<CategoriaVocabulario> _categorias = categoriasVocabulario;
  String _busqueda = '';

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
      setState(() {
        _categoriaSeleccionada = null;
        _busqueda = '';
      });
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
                          _busqueda = '';
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
  static String _normalizar(String t) => t
      .toLowerCase()
      .replaceAll(RegExp('[áà]'), 'a')
      .replaceAll(RegExp('[éè]'), 'e')
      .replaceAll(RegExp('[íì]'), 'i')
      .replaceAll(RegExp('[óò]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u');

  List<ElementoVocabulario> _filtrados(CategoriaVocabulario cat) {
    final q = _normalizar(_busqueda.trim());
    if (q.isEmpty) return cat.elementos;
    return cat.elementos
        .where((e) =>
            _normalizar(e.nombre).contains(q) ||
            (e.simboloTexto != null && _normalizar(e.simboloTexto!).startsWith(q)))
        .toList();
  }

  Widget _buscador(CategoriaVocabulario cat) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEAE2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorBorde, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: colorTextoSecundario, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _busqueda = v),
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontFamily: 'Atkinson Hyperlegible Next', fontSize: 16, color: colorTextoPrincipal),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: cat.buscador,
                hintStyle: const TextStyle(fontFamily: 'Atkinson Hyperlegible Next', fontSize: 16, color: colorTextoSecundario),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrillaCategoriaView() {
    final cat = _categoriaSeleccionada!;
    final lista = _filtrados(cat);
    final esLetra = cat.id == 'letras';

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
              _buscador(cat),
              const SizedBox(height: 12),
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
                  itemCount: lista.length,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final item = lista[index];
                    final esFav = _favoritosService.esFavorito(item.id);

                    return InkWell(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _indiceDetalle = cat.elementos.indexOf(item);
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
                                    width: 110,
                                    height: esLetra ? 110 : 80,
                                    child: _buildItemVisual(item, size: esLetra ? 100 : 76),
                                  ),
                                  if (!esLetra) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      item.nombre,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      style: const TextStyle(
                                        fontFamily: 'Atkinson Hyperlegible Next',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: colorTextoPrincipal,
                                      ),
                                    ),
                                  ],
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
    final esLetra = cat.id == 'letras';
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
                          color: esLetra ? const Color(0xFFEDF3F5) : Colors.white,
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
                                if (!esLetra) ...[
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
                                ],
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

    if (item.forma != null) {
      return DibujoForma(forma: item.forma!, tamano: size);
    }

    // Números y letras en negro, como en el Figma («61», «Gg»)
    if (item.simboloTexto != null) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          item.simboloTexto!,
          style: TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontSize: size * 0.72,
            height: 1.0,
            fontWeight: FontWeight.w700,
            color: Colors.black,
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
          border: Border.all(color: const Color(0x33000000), width: 1),
        ),
      );
    }

    return Icon(Icons.star_rounded, size: size * 0.7, color: colorTealPrimario);
  }
}
