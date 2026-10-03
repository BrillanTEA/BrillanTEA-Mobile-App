import 'package:flutter/material.dart';

import '../../dominio/favoritos_service.dart';
import '../../dominio/registro_uso_service.dart';
import '../../infraestructura/servicio_voz.dart';

/// Favoritos del niño: tarjetas guardadas o estado vacío.
class FavoritosPage extends StatefulWidget {
  final VoidCallback? onBack;

  const FavoritosPage({super.key, this.onBack});

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorEstrellaActiva = Color(0xFFF59E0B);
  static const Color colorCirculoVacio = Color(0xFFDDE9EC);

  final ServicioVoz _tts = ServicioVoz();
  final FavoritosService _favoritosService = FavoritosService();

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
    try {
      await _tts.stop();
      await _tts.speak(texto);
    } catch (_) {}
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _favoritosService.favoritos;

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
                  const Text(
                    'Favoritos',
                    style: TextStyle(
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
                child: items.isEmpty
                    ? _buildEstadoVacio()
                    : _buildListaFavoritos(items),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 132,
              height: 132,
              decoration: const BoxDecoration(
                color: colorCirculoVacio,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.star_outline_rounded,
                  size: 64,
                  color: colorTealPrimario,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Aún no tienes favoritos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colorTextoPrincipal,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Toca la estrellita de un dibujo para guardarlo aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: 16.5,
                fontWeight: FontWeight.w400,
                color: colorTextoSecundario,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaFavoritos(List<FavoritoItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Toca uno para ir directo',
          style: TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorTextoPrincipal,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            itemCount: items.length,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              final fav = items[index];

              return InkWell(
                onTap: () {
                  _favoritosService.registrarUso(fav.id);
                  _hablar(fav.fraseVoz);
                  RegistroUsoService().registrar(RegistroUsoService.pictograma, fav.id, etiqueta: fav.nombre);
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colorTealPrimario, width: 2.0),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: fav.assetPath != null
                                  ? Image.asset(
                                      fav.assetPath!,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                      errorBuilder: (c, e, s) => const Icon(
                                        Icons.image_outlined,
                                        size: 48,
                                        color: colorTealPrimario,
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        fav.simboloTexto ?? '★',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: colorTealPrimario,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              fav.nombre,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Atkinson Hyperlegible Next',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colorTextoPrincipal,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: fav.colorModulo,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  fav.modulo,
                                  style: const TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colorTextoSecundario,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Positioned(
                        top: 0,
                        right: 0,
                        child: Semantics(button: true, label: 'Marcar como favorito', child: InkWell(
                          onTap: () {
                            _favoritosService.eliminarFavorito(fav.id);
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: colorBorde, width: 1.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1F000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.star_rounded,
                                color: colorEstrellaActiva,
                                size: 18,
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
    );
  }
}
