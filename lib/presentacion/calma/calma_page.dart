import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../../dominio/accesibilidad_service.dart';
import '../../dominio/auth_service.dart';
import '../../dominio/registro_uso_service.dart';
import '../../dominio/sesion_calma.dart';
import '../../infraestructura/servicio_voz.dart';
import '../vocabulario/emociones_page.dart';

/// Módulo Calma.
///
/// Flujo:
///   Menú → Respirar / Descansar / Aprieta y suelta
///        → ¿Cómo te sientes ahora? → Mejor (¡Qué bien!) / Igual (¿Qué quieres hacer?) / Peor (Pedir ayuda)
///   Pedir ayuda → Soy el adulto · Ver aviso → Aviso para el adulto → Tu adulto ya está contigo
///
/// Íconos e ilustraciones incluidos en assets/images/calma/.
/// Si falta alguno, se muestra un ícono de respaldo.

const String _fuente = 'Atkinson Hyperlegible Next';
const Color _texto = Color(0xFF3A3A3A);
const Color _textoSecundario = Color(0xFF6B6B66);
const Color _teal = Color(0xFF3D6D7E);
const Color _tealOscuro = Color(0xFF28545B);
const Color _verdeCalma = Color(0xFFE3EFED);
const Color _borde = Color(0xFFDDD6C9);
const Color _lineaBarra = Color(0xFFEDE8E0);
const String _dir = 'assets/images/calma';

/// Callbacks de la barra inferior, compartidos por todas las pantallas del módulo.
class _NavCalma {
  final VoidCallback? onIrInicio;
  final VoidCallback? onIrFavoritos;
  const _NavCalma(this.onIrInicio, this.onIrFavoritos);

  void inicio(BuildContext context) =>
      onIrInicio != null ? onIrInicio!() : Navigator.of(context).popUntil((r) => r.isFirst);

  void favoritos(BuildContext context) =>
      onIrFavoritos != null ? onIrFavoritos!() : Navigator.of(context).popUntil((r) => r.isFirst);
}

/// Voz compartida del módulo (misma configuración que Emociones).
class _Voz {
  static final ServicioVoz _tts = ServicioVoz();
  static bool _lista = false;

  static Future<void> _preparar() async {
    if (_lista) return;
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      _lista = true;
    } catch (_) {}
  }

  /// [siempre]: el botón "Escuchar" habla aunque la lectura en voz alta esté apagada.
  static Future<void> decir(String texto, {bool siempre = false}) async {
    if (!siempre && !AccesibilidadService().leerVozAlta) return;
    await _preparar();
    try {
      await _tts.stop();
      await _tts.speak(texto);
    } catch (_) {}
  }

  static Future<void> parar() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

// Piezas comunes

/// SVG de assets/images/calma con respaldo si el archivo todavía no existe.
class _Svg extends StatelessWidget {
  final String archivo;
  final double ancho;
  final double alto;
  final IconData respaldo;
  final Color colorRespaldo;

  const _Svg(this.archivo, this.ancho, this.alto,
      {super.key, this.respaldo = Icons.spa_outlined, this.colorRespaldo = _tealOscuro});

  static final Map<String, Future<bool>> _existe = {};

  Future<bool> _hay() => _existe.putIfAbsent(
        archivo,
        () => rootBundle.load('$_dir/$archivo').then((_) => true, onError: (_) => false),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: alto,
      child: FutureBuilder<bool>(
        future: _hay(),
        builder: (context, snap) {
          if (snap.data == true) {
            return SvgPicture.asset('$_dir/$archivo', width: ancho, height: alto);
          }
          if (snap.connectionState != ConnectionState.done) return const SizedBox.shrink();
          return Icon(respaldo, size: alto * 0.8, color: colorRespaldo);
        },
      ),
    );
  }
}

/// Imagen PNG de assets/images/calma con respaldo.
Widget _png(String archivo, double ancho, double alto,
    {BoxFit fit = BoxFit.contain, Alignment alignment = Alignment.center}) {
  return SizedBox(
    width: ancho,
    height: alto,
    child: Image.asset(
      '$_dir/$archivo',
      fit: fit,
      alignment: alignment,
      errorBuilder: (c, e, s) => Icon(Icons.face_retouching_natural, size: alto * 0.6, color: _tealOscuro),
    ),
  );
}

class _BotonVolver extends StatelessWidget {
  final VoidCallback onTap;
  const _BotonVolver({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Volver',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _borde, width: 1.5),
          ),
          child: const Icon(Icons.arrow_back, color: _texto, size: 22),
        ),
      ),
    );
  }
}

/// Encabezado: botón volver y, si hay, título a su derecha.
class _Encabezado extends StatelessWidget {
  final String? titulo;
  final VoidCallback onVolver;
  const _Encabezado({this.titulo, required this.onVolver});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          _BotonVolver(onTap: onVolver),
          if (titulo != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titulo!,
                style: const TextStyle(
                  fontFamily: _fuente,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: _texto,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarraInferior extends StatelessWidget {
  final _NavCalma nav;
  const _BarraInferior(this.nav);

  Widget _pestana(BuildContext context, IconData icono, String texto, Color color, VoidCallback onTap) {
    return Expanded(
      child: Semantics(
        button: true,
        label: texto,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, color: color, size: 24),
              const SizedBox(height: 4),
              Text(texto,
                  style: TextStyle(fontFamily: _fuente, fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _lineaBarra, width: 1.5)),
        ),
        child: Row(
          children: [
            _pestana(context, Icons.home_rounded, 'Inicio', _teal, () => nav.inicio(context)),
            _pestana(context, Icons.star_outline_rounded, 'Favoritos', _textoSecundario,
                () => nav.favoritos(context)),
          ],
        ),
      ),
    );
  }
}

class _BotonPrimario extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;
  const _BotonPrimario(this.texto, this.onTap);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(texto, style: const TextStyle(fontFamily: _fuente, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _BotonSecundario extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;
  final Widget? icono;
  final double alto;
  final double tamano;
  const _BotonSecundario(this.texto, this.onTap, {this.icono, this.alto = 52, this.tamano = 16});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: alto,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _teal,
          side: const BorderSide(color: _borde, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[icono!, const SizedBox(width: 10)],
            Text(texto, style: TextStyle(fontFamily: _fuente, fontSize: tamano, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Botón "Escuchar" con el ícono de parlante de Figma.
Widget _botonEscuchar(String frase) => _BotonSecundario(
      'Escuchar',
      () => _Voz.decir(frase, siempre: true),
      alto: 50,
      tamano: 15,
      icono: const _Svg('icono_escuchar.svg', 18, 18, respaldo: Icons.volume_up_rounded, colorRespaldo: _teal),
    );

/// Píldora "Muéstrale esta pantalla a un adulto".
Widget _avisoAdulto() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFFDDE9EC), borderRadius: BorderRadius.circular(999)),
      child: const Text(
        'Muéstrale esta pantalla a un adulto',
        style: TextStyle(fontFamily: _fuente, fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2F5563)),
      ),
    );

/// Botón blanco circular con flecha (Figma "Botón ir").
Widget _botonIr() => Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Icon(Icons.chevron_right_rounded, size: 28, color: _tealOscuro),
    );

/// Andamio común: encabezado, contenido desplazable y barra inferior.
class _Pantalla extends StatelessWidget {
  final _NavCalma nav;
  final String? titulo;
  final VoidCallback? onVolver;
  final Widget hijo;
  const _Pantalla({required this.nav, required this.hijo, this.titulo}) : onVolver = null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _BarraInferior(nav),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Encabezado(titulo: titulo, onVolver: onVolver ?? () => Navigator.maybePop(context)),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), child: hijo),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Menú

class CalmaPage extends StatelessWidget {
  /// Nombre de ruta para volver al menú desde "Hacer calma otra vez".
  static const String ruta = '/calma';

  final VoidCallback? onIrInicio;
  final VoidCallback? onIrFavoritos;
  const CalmaPage({super.key, this.onIrInicio, this.onIrFavoritos});

  _NavCalma get _nav => _NavCalma(onIrInicio, onIrFavoritos);

  void _abrir(BuildContext context, Widget pagina) {
    AccesibilidadService().feedbackInteraccion();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pagina));
  }

  Widget _opcion(BuildContext context,
      {required String titulo, required Widget icono, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Semantics(
        button: true,
        label: titulo,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 148,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(color: _verdeCalma, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: icono,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(titulo,
                      style: const TextStyle(fontFamily: _fuente, fontSize: 20, fontWeight: FontWeight.w700, color: _texto)),
                ),
                _botonIr(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = _nav;
    return _Pantalla(
      nav: nav,
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Calma',
              style: TextStyle(fontFamily: _fuente, fontSize: 24, fontWeight: FontWeight.w700, color: _texto)),
          const SizedBox(height: 4),
          const Text('¿Qué quieres hacer?',
              style: TextStyle(fontFamily: _fuente, fontSize: 13.5, color: _textoSecundario)),
          const SizedBox(height: 18),
          _opcion(context,
              titulo: 'Respirar',
              icono: const _Svg('calma_respirar.svg', 64, 64, respaldo: Icons.air_rounded),
              onTap: () => _abrir(context, _CalmaEjercicioPage.respirar(nav: nav))),
          _opcion(context,
              titulo: 'Descansar',
              icono: const _Svg('calma_descansar_menu.svg', 64, 64, respaldo: Icons.bedtime_outlined),
              onTap: () => _abrir(context, _DescansarPage(nav: nav))),
          _opcion(context,
              titulo: 'Aprieta y suelta',
              icono: const _Svg('calma_puno_menu.svg', 68, 68, respaldo: Icons.back_hand_outlined),
              onTap: () => _abrir(context, _CalmaEjercicioPage.aprieta(nav: nav))),
        ],
      ),
    );
  }
}

// Ejercicios guiados (Respirar y Aprieta y suelta): 3 vueltas de 2 fases de 4 segundos

enum _TipoEjercicio { respirar, aprieta }

class _Fase {
  final String nombre;
  final String instruccion;
  const _Fase(this.nombre, this.instruccion);
}

class _CalmaEjercicioPage extends StatefulWidget {
  final _TipoEjercicio tipo;
  final _NavCalma nav;
  final int vueltas;
  final int segundosPorFase;

  const _CalmaEjercicioPage._(this.tipo, this.nav) : segundosPorFase = 4, vueltas = 3;

  factory _CalmaEjercicioPage.respirar({required _NavCalma nav}) =>
      _CalmaEjercicioPage._(_TipoEjercicio.respirar, nav);

  factory _CalmaEjercicioPage.aprieta({required _NavCalma nav}) =>
      _CalmaEjercicioPage._(_TipoEjercicio.aprieta, nav);

  @override
  State<_CalmaEjercicioPage> createState() => _CalmaEjercicioPageState();
}

class _CalmaEjercicioPageState extends State<_CalmaEjercicioPage> {
  static const _fasesRespirar = [
    _Fase('Inhala', 'Por la nariz, despacito'),
    _Fase('Exhala', 'Por la boca, soplando suave'),
  ];
  static const _fasesAprieta = [
    _Fase('Aprieta', 'Aprieta fuerte los puños'),
    _Fase('Suelta', 'Abre las manos despacito'),
  ];

  Timer? _reloj;
  int _vuelta = 1;
  int _fase = 0;
  late int _restantes;
  bool _expandido = false; // controla la animación del círculo al respirar

  bool get _esRespirar => widget.tipo == _TipoEjercicio.respirar;
  List<_Fase> get _fases => _esRespirar ? _fasesRespirar : _fasesAprieta;
  String get _titulo => _esRespirar ? 'Respirar' : 'Aprieta y suelta';

  @override
  void initState() {
    super.initState();
    _restantes = widget.segundosPorFase;
    RegistroUsoService().registrar(RegistroUsoService.calma, _esRespirar ? 'respirar' : 'aprieta',
        etiqueta: _titulo);
    SesionCalma.registrarIntento(_esRespirar ? 'Respirar despacito' : 'Aprieta y suelta');
    WidgetsBinding.instance.addPostFrameCallback((_) => _empezarFase());
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) => _tic());
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _Voz.parar();
    super.dispose();
  }

  void _empezarFase() {
    if (!mounted) return;
    setState(() => _expandido = _fase == 0);
    _Voz.decir(_fases[_fase].nombre);
    AccesibilidadService().feedbackInteraccion();
  }

  void _tic() {
    if (!mounted) return;
    if (_restantes > 1) {
      setState(() => _restantes--);
      return;
    }
    if (_fase == 0) {
      setState(() {
        _fase = 1;
        _restantes = widget.segundosPorFase;
      });
      _empezarFase();
    } else if (_vuelta < widget.vueltas) {
      setState(() {
        _vuelta++;
        _fase = 0;
        _restantes = widget.segundosPorFase;
      });
      _empezarFase();
    } else {
      _reloj?.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => _ComoTeSientesPage(nav: widget.nav)),
      );
    }
  }

  Widget _visualRespirar() {
    final d = Duration(seconds: widget.segundosPorFase);
    const curva = Curves.easeInOut;
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo exterior (aro claro, 260)
          const _Svg('c_ext_exh.svg', 260, 260, respaldo: Icons.circle, colorRespaldo: Color(0xFFEFF5F4)),
          // Círculo medio: 260 al inhalar, 190 al exhalar
          AnimatedScale(
            scale: _expandido ? 1 : 190 / 260,
            duration: d,
            curve: curva,
            child: const _Svg('c_med_inh.svg', 260, 260, respaldo: Icons.circle, colorRespaldo: Color(0xFFCFE3E1)),
          ),
          // Círculo principal: 236 al inhalar, 150 al exhalar
          AnimatedScale(
            scale: _expandido ? 1 : 150 / 236,
            duration: d,
            curve: curva,
            child: const _Svg('c_pri_inh.svg', 236, 236, respaldo: Icons.circle, colorRespaldo: _tealOscuro),
          ),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 600),
            style: TextStyle(
              fontFamily: _fuente,
              fontSize: _expandido ? 34 : 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            child: Text(_fases[_fase].nombre),
          ),
        ],
      ),
    );
  }

  Widget _visualAprieta() {
    final aprieta = _fase == 0;
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const _Svg('a_ext.svg', 230, 230, respaldo: Icons.circle, colorRespaldo: Color(0xFFEFF5F4)),
          const _Svg('a_med.svg', 190, 190, respaldo: Icons.circle_outlined, colorRespaldo: Color(0xFFCFE3E1)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: aprieta
                ? const _Svg('calma_puno.svg', 120, 120, key: ValueKey('puno'), respaldo: Icons.front_hand)
                : const _Svg('calma_mano_abierta.svg', 120, 120, key: ValueKey('mano'), respaldo: Icons.back_hand_outlined),
          ),
        ],
      ),
    );
  }

  Widget _puntosVuelta() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.vueltas, (i) {
        final hecho = i < _vuelta;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: _Svg(hecho ? 'punto_on.svg' : 'punto_off.svg', 14, 14,
              respaldo: Icons.circle, colorRespaldo: hecho ? _tealOscuro : const Color(0xFFDDD6C9)),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fase = _fases[_fase];
    return _Pantalla(
      nav: widget.nav,
      titulo: _titulo,
      hijo: Column(
        children: [
          SizedBox(height: _esRespirar ? 40 : 28),
          Semantics(
            liveRegion: true,
            label: '${fase.nombre}. ${fase.instruccion}. $_restantes segundos',
            child: ExcludeSemantics(child: _esRespirar ? _visualRespirar() : _visualAprieta()),
          ),
          if (_esRespirar) ...[
            const SizedBox(height: 26),
          ] else ...[
            const SizedBox(height: 20),
            Text(fase.nombre,
                style: const TextStyle(fontFamily: _fuente, fontSize: 36, fontWeight: FontWeight.w700, color: _tealOscuro)),
            const SizedBox(height: 4),
          ],
          Text(fase.instruccion,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: _fuente, fontSize: _esRespirar ? 20 : 18, fontWeight: FontWeight.w700, color: _texto)),
          const SizedBox(height: 10),
          Text('$_restantes',
              style: TextStyle(
                  fontFamily: _fuente,
                  fontSize: _esRespirar ? 64 : 56,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: _tealOscuro)),
          const SizedBox(height: 4),
          const Text('segundos',
              style: TextStyle(fontFamily: _fuente, fontSize: 14, fontWeight: FontWeight.w700, color: _textoSecundario)),
          const SizedBox(height: 16),
          Text('Vuelta $_vuelta de ${widget.vueltas}',
              style: const TextStyle(fontFamily: _fuente, fontSize: 13, fontWeight: FontWeight.w700, color: _textoSecundario)),
          const SizedBox(height: 10),
          _puntosVuelta(),
          const SizedBox(height: 24),
          _BotonSecundario('Parar', () => Navigator.maybePop(context)),
        ],
      ),
    );
  }
}

// Descansar y Pedir ayuda: tarjeta grande para mostrar al adulto

class _TarjetaParaAdulto extends StatelessWidget {
  final _NavCalma nav;
  final String titulo;
  final String frase; // dos líneas: "Quiero un\ndescanso"
  final Widget ilustracion;
  final double altoTarjeta;
  final double tamanoFrase;
  final String textoBoton;
  final String claveRegistro;

  /// Pedir ayuda: el botón principal va arriba y abre el aviso para el adulto (Figma).
  final bool primarioArriba;
  final void Function(BuildContext context)? onPrimario;

  const _TarjetaParaAdulto({
    this.primarioArriba = false,
    this.onPrimario,
    required this.nav,
    required this.titulo,
    required this.frase,
    required this.ilustracion,
    required this.altoTarjeta,
    required this.tamanoFrase,
    required this.textoBoton,
    required this.claveRegistro,
  });

  String get _fraseHablada => frase.replaceAll('\n', ' ');

  @override
  Widget build(BuildContext context) {
    return _Pantalla(
      nav: nav,
      titulo: titulo,
      hijo: Column(
        children: [
          const SizedBox(height: 16),
          Semantics(
            label: _fraseHablada,
            child: Container(
              width: double.infinity,
              height: altoTarjeta,
              decoration: BoxDecoration(
                border: Border.all(color: _teal, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ilustracion,
                  const SizedBox(height: 18),
                  Text(frase,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: _fuente,
                          fontSize: tamanoFrase,
                          height: 32 / tamanoFrase,
                          fontWeight: FontWeight.w700,
                          color: _texto)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _avisoAdulto(),
          SizedBox(height: primarioArriba ? 20 : 44),
          if (!primarioArriba) ...[
            _botonEscuchar(_fraseHablada),
            const SizedBox(height: 10),
          ],
          _BotonPrimario(textoBoton, () {
            RegistroUsoService().registrar(RegistroUsoService.calma, claveRegistro, etiqueta: _fraseHablada);
            if (onPrimario != null) {
              onPrimario!(context);
              return;
            }
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => _ComoTeSientesPage(nav: nav)),
            );
          }),
          if (primarioArriba) ...[
            const SizedBox(height: 10),
            _botonEscuchar(_fraseHablada),
          ],
        ],
      ),
    );
  }
}

class _DescansarPage extends StatefulWidget {
  final _NavCalma nav;
  const _DescansarPage({required this.nav});

  @override
  State<_DescansarPage> createState() => _DescansarPageState();
}

class _DescansarPageState extends State<_DescansarPage> {
  @override
  void initState() {
    super.initState();
    _Voz.decir('Quiero un descanso');
    SesionCalma.registrarIntento('Descansar');
  }

  @override
  Widget build(BuildContext context) {
    return _TarjetaParaAdulto(
      nav: widget.nav,
      titulo: 'Descansar',
      frase: 'Quiero un\ndescanso',
      altoTarjeta: 340,
      tamanoFrase: 28,
      textoBoton: 'Ya descansé',
      claveRegistro: 'descansar',
      ilustracion: Container(
        width: 150,
        height: 150,
        decoration: const BoxDecoration(color: _verdeCalma, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const _Svg('calma_descanso.svg', 96, 96, respaldo: Icons.bedtime_outlined),
      ),
    );
  }
}

class _PedirAyudaPage extends StatefulWidget {
  final _NavCalma nav;
  const _PedirAyudaPage({required this.nav});

  @override
  State<_PedirAyudaPage> createState() => _PedirAyudaPageState();
}

class _PedirAyudaPageState extends State<_PedirAyudaPage> {
  @override
  void initState() {
    super.initState();
    _Voz.decir('Necesito ayuda');
    SesionCalma.pidioAyuda = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return _TarjetaParaAdulto(
      nav: widget.nav,
      titulo: 'Pedir ayuda',
      frase: 'Necesito\nayuda',
      altoTarjeta: 352,
      tamanoFrase: 30,
      textoBoton: 'Soy el adulto · Ver aviso',
      claveRegistro: 'pedir_ayuda',
      primarioArriba: true,
      onPrimario: (ctx) => Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => _AvisoAdultoPage(nav: widget.nav)),
      ),
      ilustracion: const _Svg('mano_ayuda.svg', 146, 138, respaldo: Icons.back_hand_outlined),
    );
  }
}

// ¿Cómo te sientes ahora?

class _ComoTeSientesPage extends StatelessWidget {
  final _NavCalma nav;
  const _ComoTeSientesPage({required this.nav});

  void _elegir(BuildContext context, String clave, String etiqueta, Widget destino) {
    AccesibilidadService().feedbackInteraccion();
    _Voz.decir(etiqueta);
    SesionCalma.estadoActual = clave;
    RegistroUsoService().registrar(RegistroUsoService.calma, 'despues_$clave', etiqueta: 'Después: $etiqueta');
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destino));
  }

  Widget _opcion(BuildContext context, String texto, Widget cara, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: texto,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 151,
          height: 188,
          decoration: BoxDecoration(
            border: Border.all(color: _teal, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const SizedBox(height: 22),
              SizedBox(height: 103, child: Center(child: cara)),
              const SizedBox(height: 12),
              Text(texto,
                  style: const TextStyle(fontFamily: _fuente, fontSize: 20, fontWeight: FontWeight.w700, color: _texto)),
            ],
          ),
        ),
      ),
    );
  }

  /// cara.png mide 118 × 129 y en Figma se recorta a 103 de alto desde arriba.
  Widget _caraRecortada(String archivo) => ClipRect(
        child: SizedBox(
          width: 118,
          height: 102.9,
          child: OverflowBox(
            alignment: Alignment.topCenter,
            maxHeight: 129.2,
            child: _png(archivo, 118, 129.2),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return _Pantalla(
      nav: nav,
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text('¿Cómo te sientes ahora?',
              style: TextStyle(fontFamily: _fuente, fontSize: 26, height: 30 / 26, fontWeight: FontWeight.w700, color: _texto)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _opcion(context, 'Mejor', _caraRecortada('cara_mejor.png'),
                  () => _elegir(context, 'mejor', 'Mejor', _QueBienPage(nav: nav))),
              _opcion(context, 'Igual', const _Svg('cara_igual.svg', 118, 98.3, respaldo: Icons.sentiment_neutral),
                  () => _elegir(context, 'igual', 'Igual', _SiguesIgualPage(nav: nav))),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: _opcion(context, 'Peor', _caraRecortada('cara_peor.png'),
                () => _elegir(context, 'peor', 'Peor', _PedirAyudaPage(nav: nav))),
          ),
        ],
      ),
    );
  }
}

// Mejor (¡Qué bien!)

class _QueBienPage extends StatelessWidget {
  final _NavCalma nav;
  const _QueBienPage({required this.nav});

  @override
  Widget build(BuildContext context) {
    return _Pantalla(
      nav: nav,
      hijo: Column(
        children: [
          const SizedBox(height: 12),
          _png('nino_feliz.png', 300, 278),
          const SizedBox(height: 40),
          const Text('¡Qué bien!',
              style: TextStyle(fontFamily: _fuente, fontSize: 34, fontWeight: FontWeight.w700, color: _texto)),
          const SizedBox(height: 10),
          const Text('Ya te sientes mejor.', style: TextStyle(fontFamily: _fuente, fontSize: 19, color: _texto)),
          const SizedBox(height: 50),
          _BotonPrimario('Ir al inicio', () => nav.inicio(context)),
          const SizedBox(height: 10),
          _BotonSecundario('Elegir otra emoción', () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const EmocionesPage()));
          }, tamano: 15),
        ],
      ),
    );
  }
}

// Igual (¿Qué quieres hacer?)

class _SiguesIgualPage extends StatelessWidget {
  final _NavCalma nav;
  const _SiguesIgualPage({required this.nav});

  Widget _opcion(String texto, Widget icono, Color fondo, Color? borde, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: texto,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 106,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(20),
            border: borde == null ? null : Border.all(color: borde, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: icono,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(texto,
                    style: const TextStyle(fontFamily: _fuente, fontSize: 20, fontWeight: FontWeight.w700, color: _texto)),
              ),
              _botonIr(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Pantalla(
      nav: nav,
      hijo: Column(
        children: [
          const SizedBox(height: 8),
          _png('nino_igual.png', 250, 235),
          const SizedBox(height: 14),
          const Text('Sigues igual',
              style: TextStyle(fontFamily: _fuente, fontSize: 30, fontWeight: FontWeight.w700, color: _texto)),
          const SizedBox(height: 6),
          const Text('¿Qué quieres hacer?',
              style: TextStyle(fontFamily: _fuente, fontSize: 17, color: _textoSecundario)),
          const SizedBox(height: 18),
          _opcion(
            'Hacer calma otra vez',
            const _Svg('calma_respirar_igual.svg', 48, 48, respaldo: Icons.air_rounded),
            _verdeCalma,
            null,
            () {
              // Vuelve al menú de Calma (o al inicio si se entró por otro camino)
              Navigator.of(context).popUntil((r) => r.settings.name == CalmaPage.ruta || r.isFirst);
            },
          ),
          const SizedBox(height: 12),
          _opcion(
            'Pedir ayuda',
            const _Svg('mano_igual.svg', 52, 52, respaldo: Icons.back_hand_outlined),
            const Color(0xFFEFEAE2),
            _borde,
            () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => _PedirAyudaPage(nav: nav)),
            ),
          ),
        ],
      ),
    );
  }
}

// Aviso para el adulto (Figma «Calma · Aviso para el adulto»): resume la sesión y sugiere qué hacer

class _AvisoAdultoPage extends StatefulWidget {
  final _NavCalma nav;
  const _AvisoAdultoPage({required this.nav});

  @override
  State<_AvisoAdultoPage> createState() => _AvisoAdultoPageState();
}

class _AvisoAdultoPageState extends State<_AvisoAdultoPage> {
  String _nombre = 'El niño';
  bool _esNina = false;

  @override
  void initState() {
    super.initState();
    _Voz.parar();
    _cargarNombre();
  }

  Future<void> _cargarNombre() async {
    final nino = await AuthService().getPerfilNino();
    if (nino != null && mounted) {
      setState(() {
        _nombre = nino.nombre.trim().isEmpty ? _nombre : nino.nombre.trim();
        _esNina = nino.avatar == 'nina';
      });
    }
  }

  String get _haceCuanto {
    final desde = SesionCalma.pidioAyuda;
    if (desde == null) return 'hace un momento';
    final min = DateTime.now().difference(desde).inMinutes;
    if (min < 1) return 'hace un momento';
    return min == 1 ? 'hace 1 minuto' : 'hace $min minutos';
  }

  /// La emoción en minúsculas para la sugerencia «Veo que estás triste».
  String get _emocionEnFrase {
    final e = SesionCalma.emocionNombre;
    if (e == null) return 'mal';
    final base = e.toLowerCase();
    if (_esNina && base.endsWith('o')) return '${base.substring(0, base.length - 1)}a';
    return base;
  }

  Widget _etiqueta(String texto) => Text(
        texto,
        style: const TextStyle(
          fontFamily: _fuente,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: _textoSecundario,
        ),
      );

  Widget _paso(int n, String texto) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: _tealOscuro, shape: BoxShape.circle),
              child: Text('$n',
                  style: const TextStyle(fontFamily: _fuente, fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(texto, style: const TextStyle(fontFamily: _fuente, fontSize: 14.5, height: 1.35, color: _texto)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final emocion = SesionCalma.emocionNombre;
    final intentos = SesionCalma.intentos;
    return _Pantalla(
      nav: widget.nav,
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text('$_nombre necesita ayuda',
              style: const TextStyle(fontFamily: _fuente, fontSize: 22, fontWeight: FontWeight.w700, color: _texto)),
          const SizedBox(height: 2),
          Text('Aviso para el adulto · $_haceCuanto',
              style: const TextStyle(fontFamily: _fuente, fontSize: 14, color: _textoSecundario)),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: _borde, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: _teal, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SesionCalma.emocionAsset != null
                            ? Image.asset(SesionCalma.emocionAsset!, fit: BoxFit.contain)
                            : const Icon(Icons.sentiment_neutral, color: _teal, size: 40),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _etiqueta('SE SINTIÓ'),
                            Text(emocion ?? 'Sin elegir',
                                style: const TextStyle(
                                    fontFamily: _fuente, fontSize: 22, fontWeight: FontWeight.w700, color: _texto)),
                            Text(emocion == null ? 'Entró directo a Calma' : 'Lo eligió al empezar',
                                style: const TextStyle(fontFamily: _fuente, fontSize: 12.5, color: _textoSecundario)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1.5, thickness: 1.5, color: _borde),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _etiqueta('QUÉ INTENTÓ'),
                      if (intentos.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('Todavía ningún ejercicio',
                              style: TextStyle(fontFamily: _fuente, fontSize: 14.5, color: _texto)),
                        ),
                      for (final i in intentos)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(color: Color(0xFFCFE3D2), shape: BoxShape.circle),
                                child: const Icon(Icons.check_rounded, size: 15, color: Color(0xFF3F5E48)),
                              ),
                              const SizedBox(width: 8),
                              Text(i, style: const TextStyle(fontFamily: _fuente, fontSize: 14.5, color: _texto)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1.5, thickness: 1.5, color: _borde),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _etiqueta('AHORA'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(color: const Color(0xFFEFEAE2), borderRadius: BorderRadius.circular(999)),
                        child: Text(SesionCalma.textoEstado,
                            style: const TextStyle(fontFamily: _fuente, fontSize: 15, fontWeight: FontWeight.w700, color: _texto)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(color: const Color(0xFFDDE9EC), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('QUÉ PUEDES HACER AHORA',
                    style: TextStyle(
                        fontFamily: _fuente, fontSize: 11.5, fontWeight: FontWeight.w700, color: _tealOscuro)),
                _paso(1, 'Acércate y háblale bajito, con pocas palabras.'),
                _paso(2, 'Dile: «Veo que estás $_emocionEnFrase. Estoy aquí contigo».'),
                _paso(3, 'Ofrécele su objeto favorito o un lugar tranquilo.'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text('Sugerencias generales. No reemplazan la guía de su especialista.',
              style: TextStyle(fontFamily: _fuente, fontSize: 11.5, color: _textoSecundario)),
          const SizedBox(height: 14),
          _BotonPrimario('Ya estoy con $_nombre', () {
            RegistroUsoService().registrar(RegistroUsoService.calma, 'adulto_presente', etiqueta: 'El adulto acudió');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => _AdultoContigoPage(nav: widget.nav)),
            );
          }),
        ],
      ),
    );
  }
}

// Tu adulto ya está contigo (Figma «Calma · Tu adulto está contigo»)

class _AdultoContigoPage extends StatelessWidget {
  final _NavCalma nav;
  const _AdultoContigoPage({required this.nav});

  @override
  Widget build(BuildContext context) {
    return _Pantalla(
      nav: nav,
      hijo: Column(
        children: [
          const SizedBox(height: 96),
          Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(color: Color(0xFFCFE3D2), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 72, color: Color(0xFF3F7A4E)),
          ),
          const SizedBox(height: 24),
          const Text('Tu adulto ya está contigo',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: _fuente, fontSize: 26, fontWeight: FontWeight.w700, color: _texto)),
          const SizedBox(height: 6),
          const Text('Estás a salvo.', style: TextStyle(fontFamily: _fuente, fontSize: 16, color: _textoSecundario)),
          const SizedBox(height: 120),
          _BotonPrimario('Listo', () => nav.inicio(context)),
        ],
      ),
    );
  }
}
