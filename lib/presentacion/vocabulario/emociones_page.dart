import 'package:flutter/material.dart';

import '../../dominio/accesibilidad_service.dart';
import '../../dominio/auth_service.dart';
import '../../dominio/favoritos_service.dart';
import '../../dominio/registro_uso_service.dart';
import '../../infraestructura/servicio_voz.dart';

class EmocionItem {
  final String id;
  final String nombre;
  final String fraseMasculina;
  final String fraseFemenina;
  final String assetPath;

  const EmocionItem({
    required this.id,
    required this.nombre,
    required this.fraseMasculina,
    required this.fraseFemenina,
    required this.assetPath,
  });

  String getFrase(bool esNina) => esNina ? fraseFemenina : fraseMasculina;

  FavoritoItem toFavoritoItem(bool esNina) {
    return FavoritoItem(
      id: 'emo_$id',
      nombre: nombre,
      modulo: 'Emociones',
      colorModuloValue: 0xFF7C6BA0,
      assetPath: assetPath,
      fraseVoz: getFrase(esNina),
    );
  }
}

/// Módulo Emociones (US703, US704, US705).
class EmocionesPage extends StatefulWidget {
  final VoidCallback? onBack;

  const EmocionesPage({super.key, this.onBack});

  @override
  State<EmocionesPage> createState() => _EmocionesPageState();
}

class _EmocionesPageState extends State<EmocionesPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorEstrellaActiva = Color(0xFFD9A441);

  final ServicioVoz _tts = ServicioVoz();
  final FavoritosService _favoritosService = FavoritosService();
  final AuthService _authService = AuthService();

  String? _emocionSeleccionada;
  bool _esNina = false;

  // Control para US704: registrar emoción repetida solo 1 vez cada 3 minutos
  static final Map<String, DateTime> _ultimosRegistros = {};

  final List<EmocionItem> _emociones = const [
    EmocionItem(
      id: 'alegre',
      nombre: 'Alegre',
      fraseMasculina: 'Me siento alegre',
      fraseFemenina: 'Me siento alegre',
      assetPath: 'assets/images/emo_alegre.png',
    ),
    EmocionItem(
      id: 'triste',
      nombre: 'Triste',
      fraseMasculina: 'Me siento triste',
      fraseFemenina: 'Me siento triste',
      assetPath: 'assets/images/emo_triste.png',
    ),
    EmocionItem(
      id: 'enojado',
      nombre: 'Enojado',
      fraseMasculina: 'Me siento enojado',
      fraseFemenina: 'Me siento enojada',
      assetPath: 'assets/images/emo_enojado.png',
    ),
    EmocionItem(
      id: 'asustado',
      nombre: 'Asustado',
      fraseMasculina: 'Tengo miedo, estoy asustado',
      fraseFemenina: 'Tengo miedo, estoy asustada',
      assetPath: 'assets/images/emo_asustado.png',
    ),
    EmocionItem(
      id: 'nervioso',
      nombre: 'Nervioso',
      fraseMasculina: 'Estoy nervioso',
      fraseFemenina: 'Estoy nerviosa',
      assetPath: 'assets/images/emo_nervioso.png',
    ),
    EmocionItem(
      id: 'tranquilo',
      nombre: 'Tranquilo',
      fraseMasculina: 'Estoy tranquilo',
      fraseFemenina: 'Estoy tranquila',
      assetPath: 'assets/images/emo_tranquilo.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _cargarPerfil();
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

  Future<void> _cargarPerfil() async {
    final nino = await _authService.getPerfilNino();
    if (nino != null && mounted) {
      setState(() {
        _esNina = nino.avatar == 'nina';
      });
    }
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

  void _seleccionarEmocion(EmocionItem em) {
    setState(() {
      _emocionSeleccionada = em.id;
    });

    final frase = em.getFrase(_esNina);
    _hablar(frase);

    final ahora = DateTime.now();
    final ultimo = _ultimosRegistros[em.id];
    if (ultimo == null || ahora.difference(ultimo).inMinutes >= 3) {
      _ultimosRegistros[em.id] = ahora;
      RegistroUsoService().registrar(RegistroUsoService.emocion, em.id, etiqueta: em.nombre);
      _favoritosService.registrarUso('emo_${em.id}');
    }
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
              const SizedBox(height: 20),

              const Text(
                '¿Cómo te sientes?',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: GridView.builder(
                  itemCount: _emociones.length,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.92,
                  ),
                  itemBuilder: (context, index) {
                    final em = _emociones[index];
                    final seleccionada = _emocionSeleccionada == em.id;
                    final esFav = _favoritosService.esFavorito('emo_${em.id}');

                    return Semantics(button: true, label: em.nombre, child: InkWell(
                      onTap: () => _seleccionarEmocion(em),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorTealPrimario,
                            width: seleccionada ? 3.0 : 2.0,
                          ),
                          boxShadow: seleccionada
                              ? [
                                  BoxShadow(
                                    color: colorTealPrimario.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Center(
                                child: Image.asset(
                                  em.assetPath,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder: (c, e, s) => const Icon(
                                    Icons.mood_rounded,
                                    size: 64,
                                    color: colorTealPrimario,
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              top: -8,
                              right: -8,
                              child: Semantics(button: true, label: 'Marcar como favorito', child: InkWell(
                                onTap: () {
                                  _favoritosService.toggleFavorito(
                                    em.toFavoritoItem(_esNina),
                                  );
                                },
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: esFav ? colorEstrellaActiva : colorBorde,
                                      width: 1.5,
                                    ),
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
                                      color: esFav ? colorEstrellaActiva : colorBorde,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              )),
                            ),
                          ],
          )              ),
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
}
