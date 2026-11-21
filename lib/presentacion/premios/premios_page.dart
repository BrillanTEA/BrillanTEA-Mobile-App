import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dominio/accesibilidad_service.dart';
import '../../dominio/premios_service.dart';
import '../comun/dialogo_confirmacion.dart';
import '../comun/svg_seguro.dart';

/// Premios (Figma BrillanTEA-UX-UI):
///   - MisPremiosPage: "Mis premios" y "Mis premios · Meta lograda", para el niño.
///   - PremiosConfigPage: "Premios · Activados / Desactivados", período (diaria, semanal o mensual),
///     meta escrita con su rango, errores y los diálogos "Confirmar guardado" y "Salir sin guardar".
///     La tarjeta "Así lo verá el niño" muestra el avance real del período.
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
    final m = await PremiosService().medallasDelPeriodo(c.periodo);
    if (!mounted) return;
    setState(() {
      _config = c;
      _medallas = m;
      _cargando = false;
    });
    if (m >= c.meta) {
      AccesibilidadService().feedbackInteraccion('¡Lo lograste! Juntaste $m medallas ${c.periodo.cuando}.');
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
    final meta = _config.meta;
    final cuando = _config.periodo.cuando;
    final faltan = (meta - _medallas).clamp(0, meta);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Semantics(
          label: '$_medallas ${_medallas == 1 ? 'medalla' : 'medallas'} $cuando',
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
                    Text(_medallas == 1 ? 'medalla $cuando' : 'medallas $cuando',
                        style: const TextStyle(fontFamily: _fuente, fontSize: 16, fontWeight: FontWeight.w700, color: _texto)),
                  ],
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        Text('${_config.periodo.tituloMeta}: $meta medallas',
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
        Text('Juntaste $_medallas medallas ${_config.periodo.cuando}.',
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
    final logrado = !_cargando && _medallas >= _config.meta;
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

// Premios (responsable): activar, elegir el período y escribir la meta (US1402)

const Color _rojo = Color(0xFFB4533F);
const Color _rojoFondo = Color(0xFFF3DCD6);

class PremiosConfigPage extends StatefulWidget {
  const PremiosConfigPage({super.key});

  @override
  State<PremiosConfigPage> createState() => _PremiosConfigPageState();
}

class _PremiosConfigPageState extends State<PremiosConfigPage> {
  final TextEditingController _metaCtrl = TextEditingController();
  final FocusNode _metaFoco = FocusNode();

  ConfigPremios _guardada = const ConfigPremios();
  bool _activados = true;
  PeriodoPremios _periodo = PeriodoPremios.semanal;
  bool _periodoAbierto = false;
  int _medallas = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _metaFoco.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _metaCtrl.dispose();
    _metaFoco.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final c = await PremiosService().config();
    final m = await PremiosService().medallasDelPeriodo(c.periodo);
    if (!mounted) return;
    setState(() {
      _guardada = c;
      _activados = c.activados;
      _periodo = c.periodo;
      _metaCtrl.text = '${c.meta}';
      _medallas = m;
      _cargando = false;
    });
  }

  int? get _meta => int.tryParse(_metaCtrl.text.trim());
  String? get _error => PremiosService.errorMeta(_periodo, _meta);
  bool get _metaValida => _meta != null && _error == null;
  bool get _puedeGuardar => !_activados || _metaValida;

  bool get _hayCambios =>
      _activados != _guardada.activados || _periodo != _guardada.periodo || _meta != _guardada.meta;

  Future<void> _elegirPeriodo(PeriodoPremios p) async {
    final m = await PremiosService().medallasDelPeriodo(p);
    if (!mounted) return;
    setState(() {
      if (p != _periodo) _metaCtrl.text = '${p.rango.porDefecto}';
      _periodo = p;
      _periodoAbierto = false;
      _medallas = m;
    });
    AccesibilidadService().feedbackInteraccion();
  }

  Future<void> _guardar() async {
    if (!_puedeGuardar) return;
    FocusScope.of(context).unfocus();
    if (_activados) {
      final meta = _meta!;
      final ok = await mostrarDialogoConfirmacion(
        context,
        tipo: TipoDialogo.guardar,
        titulo: '¿Guardar esta meta?',
        texto: 'Meta ${_periodo.adjetivo}: $meta medallas.\nEl niño verá esta meta en Mis premios.',
        primario: 'Sí, guardar',
        secundario: 'Seguir editando',
      );
      if (ok != true) return;
    }
    await PremiosService().guardar(
      activados: _activados,
      periodo: _periodo,
      meta: _meta ?? _periodo.rango.porDefecto,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Premios guardados')));
    Navigator.of(context).pop();
  }

  String get _textoCambios {
    final g = _guardada;
    if (_meta != null && _meta != g.meta && _periodo == g.periodo) {
      return 'Cambiaste la meta de ${g.meta} a $_meta medallas.\nSi sales ahora, no se aplicará.';
    }
    if (_periodo != g.periodo) {
      return 'Cambiaste el período de ${g.periodo.adjetivo} a ${_periodo.adjetivo}.\nSi sales ahora, no se aplicará.';
    }
    if (_activados != g.activados) {
      return 'Cambiaste ${_activados ? 'a premios activados' : 'a premios desactivados'}.\nSi sales ahora, no se aplicará.';
    }
    return 'Si sales ahora, no se aplicarán los cambios.';
  }

  Future<void> _intentarSalir() async {
    if (!_hayCambios) {
      Navigator.of(context).pop();
      return;
    }
    FocusScope.of(context).unfocus();
    final seguir = await mostrarDialogoConfirmacion(
      context,
      tipo: TipoDialogo.aviso,
      titulo: '¿Salir sin guardar?',
      texto: _textoCambios,
      primario: 'Seguir editando',
      secundario: 'Salir sin guardar',
      secundarioRojo: true,
    );
    if (seguir == false && mounted) Navigator.of(context).pop();
  }

  Widget _etiquetaCampo(String t, Color c) => Text(t,
      style: TextStyle(fontFamily: _fuente, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: c));

  /// «Así lo verá el niño»: barra con el avance real del período y la meta escrita.
  Widget _vistaPrevia() {
    final meta = _metaValida ? _meta! : null;
    final faltan = meta == null ? null : (meta - _medallas).clamp(0, meta);
    final apagada = meta == null;
    return Semantics(
      label: meta == null
          ? 'Así lo verá el niño: falta escribir una meta válida'
          : 'Así lo verá el niño: te faltan $faltan, meta $meta',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: _amarilloFondo,
            border: Border.all(color: _amarilloBorde, width: 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Opacity(
            opacity: apagada ? 0.45 : 1,
            child: Column(children: [
              const Text('Así lo verá el niño',
                  style: TextStyle(fontFamily: _fuente, fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6E5A1F))),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _barraProgreso(meta == null ? 0 : _medallas, meta ?? 1, 18)),
                const SizedBox(width: 6),
                Opacity(opacity: 0.55, child: medalla(46)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Text('Te faltan ${faltan ?? '—'}',
                    style: const TextStyle(fontFamily: _fuente, fontSize: 13, fontWeight: FontWeight.w700, color: _texto)),
                const Spacer(),
                Text('Meta: ${meta ?? '—'}',
                    style: const TextStyle(fontFamily: _fuente, fontSize: 13, fontWeight: FontWeight.w700, color: _texto)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _selectorPeriodo() {
    final borde = _periodoAbierto || _activados ? _teal : _borde;
    return Column(children: [
      Semantics(
        button: true,
        label: 'Período: ${_periodo.nombre}',
        expanded: _periodoAbierto,
        child: InkWell(
          onTap: _activados ? () => setState(() => _periodoAbierto = !_periodoAbierto) : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: borde, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _etiquetaCampo('PERÍODO', _textoSecundario),
                  const SizedBox(height: 2),
                  Text(_periodo.nombre,
                      style: const TextStyle(fontFamily: _fuente, fontSize: 18, fontWeight: FontWeight.w700, color: _teal)),
                ]),
              ),
              Icon(_periodoAbierto ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: _teal, size: 28),
            ]),
          ),
        ),
      ),
      if (_periodoAbierto)
        Container(
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _teal, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            for (final p in PeriodoPremios.values)
              Semantics(
                button: true,
                selected: p == _periodo,
                label: p.nombre,
                child: InkWell(
                  onTap: () => _elegirPeriodo(p),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    color: p == _periodo ? const Color(0xFFDDE9EC) : null,
                    child: Row(children: [
                      Expanded(
                        child: Text(p.nombre,
                            style: TextStyle(
                                fontFamily: _fuente,
                                fontSize: 16,
                                fontWeight: p == _periodo ? FontWeight.w700 : FontWeight.w400,
                                color: _texto)),
                      ),
                      if (p == _periodo) const Icon(Icons.check_rounded, color: _teal, size: 24),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
    ]);
  }

  Widget _campoMeta() {
    final error = _activados ? _error : null;
    final enfocado = _metaFoco.hasFocus || _metaCtrl.text.isEmpty;
    final borde = error != null ? _rojo : (_activados && enfocado ? _teal : _borde);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: borde, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _etiquetaCampo('META', error != null ? _rojo : _textoSecundario),
              TextField(
                controller: _metaCtrl,
                focusNode: _metaFoco,
                enabled: _activados,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                    fontFamily: _fuente, fontSize: 18, fontWeight: FontWeight.w700, color: error != null ? _rojo : _texto),
                decoration: const InputDecoration(
                  isDense: true,
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 2),
                  hintText: 'Escribe un número',
                  hintStyle: TextStyle(fontFamily: _fuente, fontSize: 16, fontWeight: FontWeight.w400, color: _textoSecundario),
                ),
              ),
            ]),
          ),
          const Text('medallas', style: TextStyle(fontFamily: _fuente, fontSize: 14, color: _textoSecundario)),
        ]),
      ),
      if (error != null)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: _rojoFondo, borderRadius: BorderRadius.circular(12)),
          child: Semantics(
            liveRegion: true,
            child: Text(error,
                style: const TextStyle(fontFamily: _fuente, fontSize: 13, height: 1.35, fontWeight: FontWeight.w700, color: Color(0xFF8E3B2A))),
          ),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final r = _periodo.rango;
    final ayuda = _activados
        ? (_error == null ? 'De ${r.minimo} a ${r.maximo} medallas ${_periodo.unidad}' : null)
        : 'El niño no verá medallas ni «Mis premios».\nPuedes volver a activarlos cuando quieras.';
    return PopScope(
      canPop: !_hayCambios,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _intentarSalir();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: _teal))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BotonVolver(_intentarSalir),
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
                              const Text('Cuando el niño llegue a la meta, tú decides su premio.',
                                  style: TextStyle(fontFamily: _fuente, fontSize: 14.5, height: 1.4, color: _textoSecundario)),
                              const SizedBox(height: 14),
                              Container(
                                height: 60,
                                padding: const EdgeInsets.only(left: 16, right: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: _borde, width: 1.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(children: [
                                  Expanded(
                                    child: Text(_activados ? 'Premios activados' : 'Premios desactivados',
                                        style: const TextStyle(fontFamily: _fuente, fontSize: 17, fontWeight: FontWeight.w700, color: _texto)),
                                  ),
                                  Switch(
                                    value: _activados,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: _teal,
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: const Color(0xFFD6CDBE),
                                    onChanged: (v) => setState(() {
                                      _activados = v;
                                      _periodoAbierto = false;
                                    }),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 14),
                              Opacity(
                                opacity: _activados ? 1 : 0.45,
                                child: Column(children: [
                                  _vistaPrevia(),
                                  const SizedBox(height: 14),
                                  _selectorPeriodo(),
                                  if (!_periodoAbierto) ...[
                                    const SizedBox(height: 12),
                                    _campoMeta(),
                                  ],
                                ]),
                              ),
                              if (ayuda != null && !_periodoAbierto) ...[
                                const SizedBox(height: 12),
                                Center(
                                  child: Text(ayuda,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontFamily: _fuente, fontSize: 13, height: 1.4, color: _textoSecundario)),
                                ),
                              ],
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: _puedeGuardar ? 1 : 0.4,
                        child: _botonPrimario('Guardar', _puedeGuardar ? _guardar : null),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
