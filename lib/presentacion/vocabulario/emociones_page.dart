import 'package:flutter/material.dart';

import '../../dominio/accesibilidad_service.dart';
import '../../dominio/auth_service.dart';
import '../../dominio/favoritos_service.dart';
import '../../dominio/registro_uso_service.dart';
import '../../dominio/sesion_calma.dart';
import '../../infraestructura/servicio_voz.dart';
import '../calma/calma_page.dart';

class EmocionItem {
  final String id;
  final String nombre;
  final String fraseMasculina;
  final String fraseFemenina;
  final String assetPath;

  /// Mensaje de la pantalla de respuesta (Figma «Emociones · Respuesta»). Vacío en Alegre, que no
  /// tiene respuesta: solo se escucha.
  final String respuestaMasculina;
  final String respuestaFemenina;

  const EmocionItem({
    required this.id,
    required this.nombre,
    required this.fraseMasculina,
    required this.fraseFemenina,
    required this.assetPath,
    this.respuestaMasculina = '',
    this.respuestaFemenina = '',
  });

  String getFrase(bool esNina) => esNina ? fraseFemenina : fraseMasculina;
  String getRespuesta(bool esNina) => esNina ? respuestaFemenina : respuestaMasculina;
  bool get tieneRespuesta => respuestaMasculina.isNotEmpty;

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

/// Módulo Emociones (US703, US704, US705; Figma «Emociones», «Emociones · Scroll» y
/// «Emociones · Respuesta»). Ocho emociones; al elegir una distinta de Alegre se muestra una
/// respuesta con el acceso a Calma.
class EmocionesPage extends StatefulWidget {
  final VoidCallback? onBack;

  const EmocionesPage({super.key, this.onBack});

  static const List<EmocionItem> emociones = [
    EmocionItem(
      id: 'alegre',
      nombre: 'Alegre',
      fraseMasculina: 'Estoy feliz',
      fraseFemenina: 'Estoy feliz',
      assetPath: 'assets/images/emo_alegre.png',
    ),
    EmocionItem(
      id: 'triste',
      nombre: 'Triste',
      fraseMasculina: 'Me siento triste',
      fraseFemenina: 'Me siento triste',
      assetPath: 'assets/images/emo_triste.png',
      respuestaMasculina: 'Está bien sentirse triste.',
      respuestaFemenina: 'Está bien sentirse triste.',
    ),
    EmocionItem(
      id: 'enojado',
      nombre: 'Enojado',
      fraseMasculina: 'Me siento enojado',
      fraseFemenina: 'Me siento enojada',
      assetPath: 'assets/images/emo_enojado.png',
      respuestaMasculina: 'Está bien sentirse enojado.',
      respuestaFemenina: 'Está bien sentirse enojada.',
    ),
    EmocionItem(
      id: 'asustado',
      nombre: 'Asustado',
      fraseMasculina: 'Me siento asustado',
      fraseFemenina: 'Me siento asustada',
      assetPath: 'assets/images/emo_asustado.png',
      respuestaMasculina: 'Está bien sentir miedo.',
      respuestaFemenina: 'Está bien sentir miedo.',
    ),
    EmocionItem(
      id: 'nervioso',
      nombre: 'Nervioso',
      fraseMasculina: 'Me siento nervioso',
      fraseFemenina: 'Me siento nerviosa',
      assetPath: 'assets/images/emo_nervioso.png',
      respuestaMasculina: 'Está bien sentirse nervioso.',
      respuestaFemenina: 'Está bien sentirse nerviosa.',
    ),
    EmocionItem(
      id: 'cansado',
      nombre: 'Cansado',
      fraseMasculina: 'Me siento cansado',
      fraseFemenina: 'Me siento cansada',
      assetPath: 'assets/images/emo_cansado.png',
      respuestaMasculina: 'Está bien sentirse cansado.',
      respuestaFemenina: 'Está bien sentirse cansada.',
    ),
    EmocionItem(
      id: 'sorprendido',
      nombre: 'Sorprendido',
      fraseMasculina: 'Me siento sorprendido',
      fraseFemenina: 'Me siento sorprendida',
      assetPath: 'assets/images/emo_sorprendido.png',
      respuestaMasculina: 'Está bien sentirse sorprendido.',
      respuestaFemenina: 'Está bien sentirse sorprendida.',
    ),
    EmocionItem(
      id: 'aburrido',
      nombre: 'Aburrido',
      fraseMasculina: 'Me siento aburrido',
      fraseFemenina: 'Me siento aburrida',
      assetPath: 'assets/images/emo_aburrido.png',
      respuestaMasculina: 'Está bien sentirse aburrido.',
      respuestaFemenina: 'Está bien sentirse aburrida.',
    ),
  ];

  @override
  State<EmocionesPage> createState() => _EmocionesPageState();
}

class _EmocionesPageState extends State<EmocionesPage> {
  static const String _fuente = 'Atkinson Hyperlegible Next';
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorEstrellaActiva = Color(0xFFD9A441);

  final ServicioVoz _tts = ServicioVoz();
  final FavoritosService _favoritosService = FavoritosService();
  final AuthService _authService = AuthService();

  String? _emocionSeleccionada;
  EmocionItem? _respuesta;
  bool _esNina = false;

  // US704: una emoción repetida se registra solo una vez cada 3 minutos
  static final Map<String, DateTime> _ultimosRegistros = {};

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
      setState(() => _esNina = nino.avatar == 'nina');
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
      if (em.tieneRespuesta) _respuesta = em;
    });
    _hablar(em.getFrase(_esNina));

    final ahora = DateTime.now();
    final ultimo = _ultimosRegistros[em.id];
    if (ultimo == null || ahora.difference(ultimo).inMinutes >= 3) {
      _ultimosRegistros[em.id] = ahora;
      RegistroUsoService().registrar(RegistroUsoService.emocion, em.id, etiqueta: em.nombre);
      _favoritosService.registrarUso('emo_${em.id}');
    }
  }

  void _handleBack() {
    if (_respuesta != null) {
      setState(() => _respuesta = null);
      return;
    }
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _irACalma() {
    final em = _respuesta;
    SesionCalma.iniciar(emocionId: em?.id, emocionNombre: em?.nombre, emocionAsset: em?.assetPath);
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: CalmaPage.ruta),
      builder: (_) => const CalmaPage(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _respuesta == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _respuesta = null);
      },
      child: Scaffold(
        backgroundColor: colorFondo,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _botonVolver(),
                if (_respuesta == null) ..._lista() else ..._pantallaRespuesta(_respuesta!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _botonVolver() {
    return Semantics(
      button: true,
      label: 'Volver',
      child: InkWell(
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
      ),
    );
  }

  List<Widget> _lista() {
    return [
      const SizedBox(height: 20),
      const Text(
        '¿Cómo te sientes?',
        style: TextStyle(
          fontFamily: _fuente,
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: colorTextoPrincipal,
        ),
      ),
      const SizedBox(height: 16),
      // Sin Scrollbar: la barra se veía como una franja blanca al costado de la cuadrícula (DEF-24).
      Expanded(
        child: GridView.builder(
          itemCount: EmocionesPage.emociones.length,
          // Mismo margen a ambos lados (la estrella de favorito sobresale 8 px) para que la
          // cuadrícula quede centrada.
          padding: const EdgeInsets.all(8),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) => _tarjeta(EmocionesPage.emociones[index]),
        ),
      ),
    ];
  }

  Widget _tarjeta(EmocionItem em) {
    final seleccionada = _emocionSeleccionada == em.id;
    final esFav = _favoritosService.esFavorito('emo_${em.id}');
    return Semantics(
      button: true,
      label: em.nombre,
      child: InkWell(
        onTap: () => _seleccionarEmocion(em),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorTealPrimario, width: seleccionada ? 3.0 : 2.0),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Ocupa toda la tarjeta: sin Positioned.fill, la columna tomaba el ancho de la imagen
              // y quedaba pegada a la izquierda (DEF-24).
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.asset(
                          em.assetPath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.mood_rounded, size: 64, color: colorTealPrimario),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        em.nombre,
                        style: const TextStyle(
                          fontFamily: _fuente,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorTextoPrincipal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: Semantics(
                  button: true,
                  label: 'Marcar como favorito',
                  child: InkWell(
                    onTap: () => _favoritosService.toggleFavorito(em.toFavoritoItem(_esNina)),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: esFav ? colorEstrellaActiva : colorBorde, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x1F000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          esFav ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: esFav ? colorEstrellaActiva : const Color(0xFF6B6B66),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _pantallaRespuesta(EmocionItem em) {
    return [
      const SizedBox(height: 24),
      Center(
        child: Container(
          width: 240,
          height: 240,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorTealPrimario, width: 2.0),
          ),
          child: Image.asset(em.assetPath, fit: BoxFit.contain),
        ),
      ),
      const SizedBox(height: 24),
      Center(
        child: Text(
          em.getFrase(_esNina),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: _fuente,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: colorTextoPrincipal,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(
          em.getRespuesta(_esNina),
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: _fuente, fontSize: 15, color: colorTextoSecundario),
        ),
      ),
      const Spacer(),
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _irACalma,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorTealPrimario,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Calma',
            style: TextStyle(fontFamily: _fuente, fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: () => setState(() {
            _respuesta = null;
            _emocionSeleccionada = null;
          }),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: colorBorde, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Elegir otra emoción',
            style: TextStyle(fontFamily: _fuente, fontSize: 15, fontWeight: FontWeight.w700, color: colorTealPrimario),
          ),
        ),
      ),
      const SizedBox(height: 8),
    ];
  }
}
