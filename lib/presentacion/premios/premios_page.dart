import 'package:flutter/material.dart';

import '../../dominio/accesibilidad_service.dart';
import '../../dominio/premios_service.dart';
import '../comun/svg_seguro.dart';

/// Premios (Figma BrillanTEA-UX-UI):
///   - MisPremiosPage: "Mis premios" y "Mis premios · Meta lograda", para el niño.
///   - PremiosConfigPage: "Premios · Activados / Desactivados" y metas 10–35, para el responsable.
///   - Vista previa: cómo lo verá el niño.
/// Íconos incluidos en assets/images/premios/.

const String _fuente = 'Atkinson Hyperlegible Next';
const Color _texto = Color(0xFF3A3A3A);
const Color _textoSecundario = Color(0xFF6B6B66);
const Color _teal = Color(0xFF3D6D7E);
const Color _borde = Color(0xFFDDD6C9);
const Color _amarilloFondo = Color(0xFFFFF8E1);
const Color _amarilloBorde = Color(0xFFF1DFA0);
const Color _barraFondo = Color(0xFFF4EBD2);
const Color _barraAvance = Color(0xFFF2B632);
const String _dir = 'assets/images/premios';

Widget medalla(double tamano) => SvgSeguro('$_dir/medalla.svg', tamano, tamano,
    respaldo: Icons.workspace_premium_rounded, colorRespaldo: const Color(0xFFE0A526));

Widget medallaGanada(double tamano) => SvgSeguro('$_dir/medalla_ganada.svg', tamano, tamano,
    respaldo: Icons.workspace_premium_rounded, colorRespaldo: const Color(0xFFE0A526));

Widget _espacio(double tamano) => SvgSeguro('$_dir/espacio.svg', tamano, tamano,
    respaldo: Icons.circle, colorRespaldo: const Color(0xFFEFEAE2));

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

Widget _botonPrimario(String texto, VoidCallback? onTap, {double alto = 56, double tamano = 17}) => SizedBox(
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
        child: Text(texto, style: TextStyle(fontFamily: _fuente, fontSize: tamano, fontWeight: FontWeight.w700)),
      ),
    );

Widget _botonSecundario(String texto, VoidCallback onTap) => SizedBox(
      width: double.infinity,
      height: 52,
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

Widget _barraProgreso(int medallas, int meta, double alto) => ClipRRect(
      borderRadius: BorderRadius.circular(alto / 2),
      child: SizedBox(
        height: alto,
        child: LinearProgressIndicator(
          value: meta <= 0 ? 0 : (medallas / meta).clamp(0.0, 1.0),
          backgroundColor: _barraFondo,
          valueColor: const AlwaysStoppedAnimation(_barraAvance),
        ),
      ),
    );

/// Cuadrícula de 5 columnas: medallas ganadas y espacios vacíos hasta la meta.
Widget _cuadriculaMedallas(int medallas, int meta, {required double medallaTam, required double espacioTam}) {
  return LayoutBuilder(builder: (context, c) {
    final celda = c.maxWidth / 5;
    return Wrap(
      children: List.generate(meta, (i) {
        final ganada = i < medallas;
        return SizedBox(
          width: celda,
          height: medallaTam + 10,
          child: Center(child: ganada ? medalla(medallaTam) : _espacio(espacioTam)),
        );
      }),
    );
  });
}

// Mis premios (niño)

class MisPremiosPage extends StatefulWidget {
  final VoidCallback? onIrInicio;
  final VoidCallback? onIrFavoritos;
  const MisPremiosPage({super.key, this.onIrInicio, this.onIrFavoritos});

  @override
  State<MisPremiosPage> createState() => _MisPremiosPageState();
}

class _MisPremiosPageState extends State<MisPremiosPage> {
  ConfigPremios _config = const ConfigPremios();
  int _medallas = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final c = await PremiosService().config();
    final m = await PremiosService().medallasSemana();
    if (!mounted) return;
    setState(() {
      _config = c;
      _medallas = m;
      _cargando = false;
    });
    if (m >= c.metaSemanal) {
      AccesibilidadService().feedbackInteraccion('¡Lo lograste! Juntaste $m medallas esta semana.');
    }
  }

  void _inicio() =>
      widget.onIrInicio != null ? widget.onIrInicio!() : Navigator.of(context).popUntil((r) => r.isFirst);

  void _favoritos() =>
      widget.onIrFavoritos != null ? widget.onIrFavoritos!() : Navigator.of(context).popUntil((r) => r.isFirst);

  Widget _barraInferior() => SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEDE8E0), width: 1.5)),
          ),
          child: Row(children: [
            _pestana(Icons.home_rounded, 'Inicio', _teal, _inicio),
            _pestana(Icons.star_outline_rounded, 'Favoritos', _textoSecundario, _favoritos),
          ]),
        ),
      );

  Widget _pestana(IconData i, String t, Color c, VoidCallback onTap) => Expanded(
        child: Semantics(
          button: true,
          label: t,
          child: InkWell(
            onTap: onTap,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(i, color: c, size: 24),
              const SizedBox(height: 4),
              Text(t, style: TextStyle(fontFamily: _fuente, fontSize: 12, fontWeight: FontWeight.w700, color: c)),
            ]),
          ),
        ),
      );

  Widget _vistaNormal() {
    final meta = _config.metaSemanal;
    final faltan = (meta - _medallas).clamp(0, meta);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Semantics(
          label: '$_medallas ${_medallas == 1 ? 'medalla' : 'medallas'} esta semana',
          child: Container(
            height: 116,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: _amarilloFondo,
              border: Border.all(color: _amarilloBorde, width: 2),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(children: [
              medalla(68),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_medallas',
                        style: const TextStyle(fontFamily: _fuente, fontSize: 30, fontWeight: FontWeight.w700, color: _texto)),
                    Text(_medallas == 1 ? 'medalla esta semana' : 'medallas esta semana',
                        style: const TextStyle(fontFamily: _fuente, fontSize: 16, fontWeight: FontWeight.w700, color: _texto)),
                  ],
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        Text('Meta de la semana: $meta medallas',
            style: const TextStyle(fontFamily: _fuente, fontSize: 15, fontWeight: FontWeight.w700, color: _texto)),
        const SizedBox(height: 10),
        _barraProgreso(_medallas, meta, 12),
        const SizedBox(height: 8),
        Text('Te faltan $faltan',
            style: const TextStyle(fontFamily: _fuente, fontSize: 12.5, fontWeight: FontWeight.w700, color: _textoSecundario)),
        const SizedBox(height: 20),
        ExcludeSemantics(child: _cuadriculaMedallas(_medallas, meta, medallaTam: 50, espacioTam: 44)),
        const SizedBox(height: 12),
        const Center(
          child: Text('Cada rutina que terminas te da una medalla.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: _fuente, fontSize: 13, fontWeight: FontWeight.w700, color: _textoSecundario)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _vistaMetaLograda() {
    return Column(
      children: [
        const SizedBox(height: 20),
        SvgSeguro('$_dir/medalla_grande.svg', 170, 170,
            respaldo: Icons.workspace_premium_rounded, colorRespaldo: const Color(0xFFE0A526)),
        const SizedBox(height: 36),
        const Text('¡Lo lograste!',
            style: TextStyle(fontFamily: _fuente, fontSize: 30, fontWeight: FontWeight.w700, color: _texto)),
        const SizedBox(height: 10),
        Text('Juntaste $_medallas medallas esta semana.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: _fuente, fontSize: 18, fontWeight: FontWeight.w700, color: _texto)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFDDE9EC), borderRadius: BorderRadius.circular(999)),
          child: const Text('Díselo a mamá o papá',
              style: TextStyle(fontFamily: _fuente, fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2F5563))),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final logrado = !_cargando && _medallas >= _config.metaSemanal;
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _barraInferior(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(children: [
                _BotonVolver(() => Navigator.maybePop(context)),
                const SizedBox(width: 12),
                const Text('Mis premios',
                    style: TextStyle(fontFamily: _fuente, fontSize: 21, fontWeight: FontWeight.w700, color: _texto)),
              ]),
            ),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(color: _teal))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      child: logrado ? _vistaMetaLograda() : _vistaNormal(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _botonPrimario('Volver a mis rutinas', () => Navigator.maybePop(context),
                  alto: logrado ? 56 : 52, tamano: logrado ? 17 : 15),
            ),
          ],
        ),
      ),
    );
  }
}

// Premios (responsable): activar y elegir la meta semanal

class PremiosConfigPage extends StatefulWidget {
  const PremiosConfigPage({super.key});

  @override
  State<PremiosConfigPage> createState() => _PremiosConfigPageState();
}

class _PremiosConfigPageState extends State<PremiosConfigPage> {
  bool _activados = true;
  int _meta = PremiosService.metaPorDefecto;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    PremiosService().config().then((c) {
      if (!mounted) return;
      setState(() {
        _activados = c.activados;
        _meta = c.metaSemanal;
        _cargando = false;
      });
    });
  }

  void _cambiarMeta(int delta) {
    final nueva = _meta + delta;
    if (nueva < PremiosService.metaMinima || nueva > PremiosService.metaMaxima) return;
    setState(() => _meta = nueva);
    AccesibilidadService().feedbackInteraccion();
  }

  Future<void> _guardar() async {
    await PremiosService().guardar(activados: _activados, metaSemanal: _meta);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Premios guardados')),
    );
    Navigator.maybePop(context);
  }

  Future<void> _vistaPrevia() async {
    final guardar = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _VistaPreviaPage(meta: _meta)),
    );
    if (guardar == true) await _guardar();
  }

  Widget _botonPaso(String signo, bool habilitado, VoidCallback onTap, String etiqueta) {
    final color = habilitado && _activados ? _teal : const Color(0xFFB9C9CE);
    return Semantics(
      button: true,
      label: etiqueta,
      enabled: habilitado && _activados,
      child: InkWell(
        onTap: habilitado && _activados ? onTap : null,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
          alignment: Alignment.center,
          child: Text(signo,
              style: TextStyle(fontFamily: _fuente, fontSize: 36, height: 1, fontWeight: FontWeight.w700, color: color)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: _teal))
            : Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BotonVolver(() => Navigator.maybePop(context)),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            const Text('Premios',
                                style: TextStyle(fontFamily: _fuente, fontSize: 22, height: 1.25, fontWeight: FontWeight.w700, color: _texto)),
                            const SizedBox(height: 4),
                            const Text('Tú decides la meta de cada semana.',
                                style: TextStyle(fontFamily: _fuente, fontSize: 14.5, height: 1.4, color: _textoSecundario)),
                            const SizedBox(height: 16),
                            Container(
                              height: 64,
                              padding: const EdgeInsets.only(left: 16, right: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: _borde, width: 1.5),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Text(_activados ? 'Premios activados' : 'Premios desactivados',
                                      style: const TextStyle(fontFamily: _fuente, fontSize: 17, fontWeight: FontWeight.w700, color: _texto)),
                                ),
                                Switch(
                                  value: _activados,
                                  activeColor: Colors.white,
                                  activeTrackColor: _teal,
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: const Color(0xFFD6CDBE),
                                  onChanged: (v) => setState(() => _activados = v),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 16),
                            Opacity(
                              opacity: _activados ? 1 : 0.45,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 22),
                                decoration: BoxDecoration(
                                  border: Border.all(color: _borde, width: 1.5),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(children: [
                                  medalla(56),
                                  const SizedBox(height: 12),
                                  const Text('Meta de la semana',
                                      style: TextStyle(fontFamily: _fuente, fontSize: 14, fontWeight: FontWeight.w700, color: _textoSecundario)),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _botonPaso('−', _meta > PremiosService.metaMinima,
                                          () => _cambiarMeta(-PremiosService.pasoMeta), 'Bajar meta'),
                                      Semantics(
                                        label: 'Meta: $_meta medallas',
                                        child: Text('$_meta',
                                            style: const TextStyle(fontFamily: _fuente, fontSize: 60, fontWeight: FontWeight.w700, color: _texto)),
                                      ),
                                      _botonPaso('+', _meta < PremiosService.metaMaxima,
                                          () => _cambiarMeta(PremiosService.pasoMeta), 'Subir meta'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('medallas',
                                      style: TextStyle(fontFamily: _fuente, fontSize: 15, fontWeight: FontWeight.w700, color: _texto)),
                                ]),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: SizedBox(
                                width: 272,
                                child: Text(
                                  _activados
                                      ? 'Cuando el niño llegue a la meta, tú decides su premio.'
                                      : 'El niño no verá medallas ni «Mis premios». Puedes volver a activarlos cuando quieras.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontFamily: _fuente, fontSize: 13.5, color: _textoSecundario),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_activados) ...[
                      _botonSecundario('Ver cómo lo verá el niño', _vistaPrevia),
                      const SizedBox(height: 10),
                    ],
                    _botonPrimario('Guardar', _guardar),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Premios · Vista previa: la tarjeta de "Mis premios" con las medallas reales de la semana.
class _VistaPreviaPage extends StatefulWidget {
  final int meta;
  const _VistaPreviaPage({required this.meta});

  @override
  State<_VistaPreviaPage> createState() => _VistaPreviaPageState();
}

class _VistaPreviaPageState extends State<_VistaPreviaPage> {
  int _medallas = 0;

  @override
  void initState() {
    super.initState();
    PremiosService().medallasSemana().then((m) {
      if (mounted) setState(() => _medallas = m);
    });
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;
    final faltan = (meta - _medallas).clamp(0, meta);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _BotonVolver(() => Navigator.pop(context, false)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFDDE9EC), borderRadius: BorderRadius.circular(999)),
                  child: const Text('Vista previa',
                      style: TextStyle(fontFamily: _fuente, fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2F5563))),
                ),
              ]),
              const SizedBox(height: 20),
              const Text('Así verá el niño sus premios.',
                  style: TextStyle(fontFamily: _fuente, fontSize: 14, fontWeight: FontWeight.w700, color: _textoSecundario)),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: _borde, width: 2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          medalla(52),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('$_medallas ${_medallas == 1 ? 'medalla' : 'medallas'}',
                                style: const TextStyle(fontFamily: _fuente, fontSize: 22, fontWeight: FontWeight.w700, color: _texto)),
                            const Text('esta semana', style: TextStyle(fontFamily: _fuente, fontSize: 13, color: _textoSecundario)),
                          ]),
                        ]),
                        const SizedBox(height: 18),
                        Text('Meta de la semana: $meta medallas',
                            style: const TextStyle(fontFamily: _fuente, fontSize: 14, fontWeight: FontWeight.w700, color: _texto)),
                        const SizedBox(height: 8),
                        _barraProgreso(_medallas, meta, 10),
                        const SizedBox(height: 6),
                        Text('Te faltan $faltan', style: const TextStyle(fontFamily: _fuente, fontSize: 12, color: _textoSecundario)),
                        const SizedBox(height: 14),
                        _cuadriculaMedallas(_medallas, meta, medallaTam: 40, espacioTam: 34),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _botonSecundario('Volver a editar', () => Navigator.pop(context, false)),
              const SizedBox(height: 10),
              _botonPrimario('Guardar', () => Navigator.pop(context, true)),
            ],
          ),
        ),
      ),
    );
  }
}
