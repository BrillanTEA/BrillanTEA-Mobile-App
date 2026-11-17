import 'package:flutter/material.dart';

import '../../dominio/tutoriales_service.dart';
import '../../infraestructura/servicio_voz.dart';
import '../inicio/inicio_page.dart';
import 'tutoriales_contenido.dart';

/// Tutoriales para el adulto (Figma BrillanTEA-UX-UI):
///   - InvitacionPage: "Invitación · Conoce BrillanTEA", al terminar el registro.
///   - TutorialesPage: "Tutoriales · Lista", desde Área de padres.
///   - _TutorialPasosPage: "Tutorial · <Módulo> · 0…6" (7 pantallas por módulo; US1502).
///   - _TutorialDetallePage: "Tutorial · Detalle" (solo Situaciones, que no tiene pasos en el Figma).
/// No hay videos en la app: el botón de reproducir lee la explicación en voz alta.
/// Los tutoriales vistos se guardan en SQLite (tabla tutorial_visto).

const String _fuente = 'Atkinson Hyperlegible Next';
const Color _texto = Color(0xFF3A3A3A);
const Color _textoSecundario = Color(0xFF6B6B66);
const Color _teal = Color(0xFF3D6D7E);
const Color _borde = Color(0xFFDDD6C9);

class Tutorial {
  final String clave;
  final String nombre;
  final String imagen;
  final Color fondo;
  final String queHace;
  final String comoUsarlo;
  final String consejo;
  const Tutorial(this.clave, this.nombre, this.imagen, this.fondo, this.queHace, this.comoUsarlo, this.consejo);

  String get guion => '$nombre. Qué hace: $queHace Cómo usarlo: $comoUsarlo Consejo: $consejo';
}

/// Los 7 módulos del Inicio, en el mismo orden.
const List<Tutorial> tutoriales = [
  Tutorial('camara', 'Cámara', 'assets/images/home_camara.png', Color(0xFFF6E4DA),
      'Reconoce objetos de la casa y muestra su pictograma junto a cada uno.',
      'Apunta la cámara a un objeto, cerca y con buena luz, y toca la tarjeta que aparece.',
      'Empiecen con objetos de las rutinas, como el jabón o la toalla.'),
  Tutorial('comunicacion', 'Comunicación', 'assets/images/home_comunicacion.png', Color(0xFFE3EEF2),
      'Ayuda al niño a pedir algo, armar una frase y responder sí o no.',
      'Toca un pictograma y la app dice la frase en voz alta.',
      'Responde siempre cuando el niño use la app para pedirte algo.'),
  Tutorial('vocabulario', 'Vocabulario', 'assets/images/home_vocabulario.png', Color(0xFFF4E6ED),
      'Enseña palabras nuevas por categorías: animales, colores, números y más.',
      'Elige una categoría, toca un pictograma y escúchalo.',
      'Repitan juntos la palabra en voz alta.'),
  Tutorial('rutinas', 'Rutinas', 'assets/images/home_rutinas.png', Color(0xFFE3EFE3),
      'Muestra paso a paso cómo hacer una actividad de cada día.',
      'Elige una rutina y acompaña al niño en cada paso.',
      'Las primeras veces, hagan la rutina juntos.'),
  Tutorial('emociones', 'Emociones', 'assets/images/home_emociones.png', Color(0xFFECE8F4),
      'Permite al niño decir cómo se siente.',
      'El niño toca la cara de su emoción y la app la dice en voz alta.',
      'Pregúntale cómo se siente en momentos tranquilos, no solo cuando está molesto.'),
  Tutorial('situaciones', 'Situaciones', 'assets/images/home_situaciones.png', Color(0xFFF5EEDD),
      'Cuenta con imágenes lo que va a pasar en una experiencia nueva, como ir al doctor.',
      'Elige una situación y avancen juntos con Siguiente.',
      'Léanla unos días antes de la experiencia.'),
  Tutorial('calma', 'Calma', 'assets/images/home_calma.png', Color(0xFFE3EFED),
      'Ofrece ejercicios cortos para calmarse: respirar, descansar y apretar y soltar.',
      'El niño elige un ejercicio y sigue la cuenta en pantalla.',
      'Practíquenlo cuando el niño esté tranquilo, para que sepa usarlo cuando lo necesite.'),
];

class _BotonVolver extends StatelessWidget {
  final VoidCallback onTap;
  const _BotonVolver(this.onTap);

  @override
  Widget build(BuildContext context) => Semantics(
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

Widget _imagen(String ruta, double ancho, double alto) => SizedBox(
      width: ancho,
      height: alto,
      child: Image.asset(ruta,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Icon(Icons.image_outlined, size: alto * 0.7, color: _teal)),
    );

Widget _primario(String texto, VoidCallback onTap, {double alto = 52}) => SizedBox(
      width: double.infinity,
      height: alto,
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

Widget _secundario(String texto, VoidCallback onTap, {double alto = 52}) => SizedBox(
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
        child: Text(texto, style: const TextStyle(fontFamily: _fuente, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );

// Invitación · Conoce BrillanTEA

class InvitacionPage extends StatelessWidget {
  const InvitacionPage({super.key});

  void _irAInicio(BuildContext context, {bool abrirTutoriales = false}) {
    final nav = Navigator.of(context);
    nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const InicioPage()), (r) => false);
    if (abrirTutoriales) {
      nav.push(MaterialPageRoute(builder: (_) => const TutorialesPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final modulos = tutoriales.take(6).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 64),
                      ExcludeSemantics(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: _borde, width: 1.5),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 86.667 / 64,
                            children: [
                              for (final m in modulos)
                                Container(
                                  decoration: BoxDecoration(color: m.fondo, borderRadius: BorderRadius.circular(14)),
                                  alignment: Alignment.center,
                                  child: _imagen(m.imagen, 56, 34),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 56),
                      const Text('Conoce BrillanTEA',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: _fuente, fontSize: 28, fontWeight: FontWeight.w700, color: _texto)),
                      const SizedBox(height: 14),
                      const Text(
                        'Mira en 1 minuto para qué sirve cada módulo y cómo acompañar a tu hijo o hija.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: _fuente, fontSize: 16, height: 23 / 16, color: _textoSecundario),
                      ),
                    ],
                  ),
                ),
              ),
              _primario('Ver tutoriales', () => _irAInicio(context, abrirTutoriales: true), alto: 56),
              const SizedBox(height: 10),
              _secundario('Más tarde', () => _irAInicio(context), alto: 56),
              const SizedBox(height: 12),
              const Text('Siempre los encontrarás en Área de padres.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: _fuente, fontSize: 12.5, color: _textoSecundario)),
            ],
          ),
        ),
      ),
    );
  }
}

// Tutoriales · Lista

class TutorialesPage extends StatefulWidget {
  const TutorialesPage({super.key});

  @override
  State<TutorialesPage> createState() => _TutorialesPageState();
}

class _TutorialesPageState extends State<TutorialesPage> {
  Set<String> _vistos = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final v = await TutorialesService().vistos();
    if (mounted) setState(() => _vistos = v);
  }

  Future<void> _abrir(int indice) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => guiasTutorial.containsKey(tutoriales[indice].clave)
            ? _TutorialPasosPage(indice: indice)
            : _TutorialDetallePage(indice: indice),
      ),
    );
    _cargar();
  }

  Widget _fila(int i) {
    final t = tutoriales[i];
    final visto = _vistos.contains(t.clave);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: '${t.nombre}, 1 minuto${visto ? ', visto' : ''}',
        child: InkWell(
          onTap: () => _abrir(i),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: _borde, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: t.fondo, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: _imagen(t.imagen, 40, 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.nombre,
                        style: const TextStyle(fontFamily: _fuente, fontSize: 16, fontWeight: FontWeight.w700, color: _texto)),
                    const SizedBox(height: 2),
                    const Text('1 min', style: TextStyle(fontFamily: _fuente, fontSize: 12.5, color: _textoSecundario)),
                  ],
                ),
              ),
              visto
                  ? Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(color: Color(0xFFC7DBC5), shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: Color(0xFF4F7A58), size: 20),
                    )
                  : const Icon(Icons.play_circle_outline_rounded, color: _teal, size: 30),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Align(alignment: Alignment.centerLeft, child: _BotonVolver(() => Navigator.maybePop(context))),
            const SizedBox(height: 20),
            const Text('Tutoriales',
                style: TextStyle(fontFamily: _fuente, fontSize: 22, height: 1.25, fontWeight: FontWeight.w700, color: _texto)),
            const SizedBox(height: 4),
            const Text('Aprende para qué sirve cada módulo.',
                style: TextStyle(fontFamily: _fuente, fontSize: 14.5, height: 1.4, color: _textoSecundario)),
            const SizedBox(height: 18),
            for (var i = 0; i < tutoriales.length; i++) _fila(i),
          ],
        ),
      ),
    );
  }
}

// Tutorial · Detalle

class _TutorialDetallePage extends StatefulWidget {
  final int indice;
  const _TutorialDetallePage({required this.indice});

  @override
  State<_TutorialDetallePage> createState() => _TutorialDetallePageState();
}

class _TutorialDetallePageState extends State<_TutorialDetallePage> {
  final ServicioVoz _tts = ServicioVoz();
  bool _hablando = false;

  Tutorial get _t => tutoriales[widget.indice];

  @override
  void initState() {
    super.initState();
    TutorialesService().marcarVisto(_t.clave);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _hablando = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _reproducir() async {
    try {
      if (_hablando) {
        await _tts.stop();
        setState(() => _hablando = false);
        return;
      }
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.48);
      setState(() => _hablando = true);
      await _tts.speak(_t.guion);
    } catch (_) {
      if (mounted) setState(() => _hablando = false);
    }
  }

  Widget _bloque(String titulo, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(fontFamily: _fuente, fontSize: 15, fontWeight: FontWeight.w700, color: _teal)),
          const SizedBox(height: 4),
          Text(texto, style: const TextStyle(fontFamily: _fuente, fontSize: 14.5, height: 20 / 14.5, color: _texto)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final siguiente = widget.indice + 1 < tutoriales.length ? tutoriales[widget.indice + 1] : null;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _BotonVolver(() => Navigator.maybePop(context)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tutorial ${widget.indice + 1} de ${tutoriales.length}',
                      style: const TextStyle(fontFamily: _fuente, fontSize: 12.5, fontWeight: FontWeight.w700, color: _textoSecundario)),
                  Text(t.nombre,
                      style: const TextStyle(fontFamily: _fuente, fontSize: 22, fontWeight: FontWeight.w700, color: _texto)),
                ]),
              ]),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Recuadro · Video (la explicación se escucha con el botón de reproducir)
                    Container(
                      height: 188,
                      width: double.infinity,
                      decoration: BoxDecoration(color: t.fondo, borderRadius: BorderRadius.circular(18)),
                      child: Stack(children: [
                        Center(child: _imagen(t.imagen, 160, 112)),
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                            child: const Text('1 min',
                                style: TextStyle(fontFamily: _fuente, fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4F7A58))),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: Semantics(
                            button: true,
                            label: _hablando ? 'Detener explicación' : 'Escuchar explicación',
                            child: InkWell(
                              onTap: _reproducir,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: Icon(_hablando ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                    color: const Color(0xFF4F7A58), size: 32),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    _bloque('Qué hace', t.queHace),
                    _bloque('Cómo usarlo', t.comoUsarlo),
                    _bloque('Consejo', t.consejo),
                  ]),
                ),
              ),
              if (siguiente != null) ...[
                _primario('Siguiente: ${siguiente.nombre}', () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => guiasTutorial.containsKey(siguiente.clave)
                          ? _TutorialPasosPage(indice: widget.indice + 1)
                          : _TutorialDetallePage(indice: widget.indice + 1),
                    ),
                  );
                }),
                const SizedBox(height: 10),
              ],
              _secundario('Volver a la lista', () => Navigator.maybePop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

// Tutorial · <Módulo> · 0…6 (US1502): «Antes de empezar», 5 pasos y «Listo»

class _TutorialPasosPage extends StatefulWidget {
  final int indice;
  const _TutorialPasosPage({required this.indice});

  @override
  State<_TutorialPasosPage> createState() => _TutorialPasosPageState();
}

class _TutorialPasosPageState extends State<_TutorialPasosPage> {
  /// 0 = Antes de empezar, 1…5 = pasos, 6 = Listo.
  int _pantalla = 0;

  Tutorial get _t => tutoriales[widget.indice];
  GuiaTutorial get _g => guiasTutorial[_t.clave]!;

  void _ir(int pantalla) {
    setState(() => _pantalla = pantalla);
    if (pantalla == 6) TutorialesService().marcarVisto(_t.clave);
  }

  String get _etiqueta {
    if (_pantalla == 0) return 'Antes de empezar';
    if (_pantalla == 6) return 'Listo';
    return 'Paso $_pantalla de 5';
  }

  Widget _barras() => Semantics(
        label: _etiqueta,
        child: ExcludeSemantics(
          child: Row(children: [
            for (var i = 1; i <= 5; i++) ...[
              if (i > 1) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: i <= _pantalla ? _teal : const Color(0xFFE6E0D4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ]),
        ),
      );

  BoxDecoration get _cajaDecoracion => BoxDecoration(
        color: _t.fondo,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color.lerp(_t.fondo, Colors.black, 0.08)!, width: 1.5),
      );

  Widget _caja() {
    if (_pantalla == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
        decoration: _cajaDecoracion,
        child: Column(children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: _imagen(_t.imagen, 92, 76),
          ),
          const SizedBox(height: 30),
          Text(_g.idea,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: _fuente, fontSize: 19, height: 1.35, fontWeight: FontWeight.w700, color: _texto)),
        ]),
      );
    }
    if (_pantalla == 6) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
        decoration: _cajaDecoracion,
        child: Column(children: [
          for (var i = 0; i < _g.consejos.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 26),
              child: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _borde, width: 1.5),
                  ),
                  child: Text('${i + 1}',
                      style: TextStyle(fontFamily: _fuente, fontSize: 15, fontWeight: FontWeight.w700, color: _g.acento)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(_g.consejos[i],
                      style: const TextStyle(fontFamily: _fuente, fontSize: 16, height: 1.35, fontWeight: FontWeight.w700, color: _texto)),
                ),
              ]),
            ),
        ]),
      );
    }
    final paso = _g.pasos[_pantalla - 1];
    return Semantics(
      image: true,
      label: 'Captura de ${_t.nombre}: ${paso.titulo}',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 312 / 330,
            child: Image.asset(
              GuiaTutorial.imagenPaso(_t.clave, _pantalla),
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => Container(
                decoration: _cajaDecoracion,
                alignment: Alignment.center,
                child: _imagen(_t.imagen, 120, 90),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textos() {
    final String titulo;
    final String texto;
    if (_pantalla == 0) {
      titulo = 'Para qué sirve';
      texto = _g.paraQueSirve;
    } else if (_pantalla == 6) {
      titulo = 'Cómo acompañar';
      texto = _g.comoAcompanar;
    } else {
      titulo = _g.pasos[_pantalla - 1].titulo;
      texto = _g.pasos[_pantalla - 1].texto;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: const TextStyle(fontFamily: _fuente, fontSize: 19, fontWeight: FontWeight.w700, color: _texto)),
      const SizedBox(height: 4),
      Text(texto, style: const TextStyle(fontFamily: _fuente, fontSize: 14.5, height: 20 / 14.5, color: _textoSecundario)),
    ]);
  }

  Widget _botones() {
    if (_pantalla == 0) return _primario('Empezar', () => _ir(1));
    if (_pantalla == 6) {
      return Column(children: [
        _primario('Terminar', () => Navigator.maybePop(context)),
        const SizedBox(height: 10),
        _secundario('Ver otra vez', () => _ir(0)),
      ]);
    }
    return Row(children: [
      Expanded(child: _secundario('Anterior', () => _ir(_pantalla - 1))),
      const SizedBox(width: 12),
      Expanded(child: _primario('Siguiente', () => _ir(_pantalla + 1))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _BotonVolver(() => Navigator.maybePop(context)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tutorial ${widget.indice + 1} de ${tutoriales.length}',
                      style: const TextStyle(fontFamily: _fuente, fontSize: 12.5, fontWeight: FontWeight.w700, color: _textoSecundario)),
                  Text(_t.nombre,
                      style: const TextStyle(fontFamily: _fuente, fontSize: 22, fontWeight: FontWeight.w700, color: _texto)),
                ]),
              ]),
              const SizedBox(height: 18),
              _barras(),
              const SizedBox(height: 8),
              Text(_etiqueta,
                  style: const TextStyle(fontFamily: _fuente, fontSize: 12.5, fontWeight: FontWeight.w700, color: _textoSecundario)),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey(_pantalla),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _caja(),
                    const SizedBox(height: 18),
                    _textos(),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              _botones(),
            ],
          ),
        ),
      ),
    );
  }
}
