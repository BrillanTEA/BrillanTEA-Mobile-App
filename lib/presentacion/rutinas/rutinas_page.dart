import 'dart:async';

import 'package:flutter/material.dart';

import '../../dominio/accesibilidad_service.dart';
import '../../dominio/premios_service.dart';
import '../../dominio/registro_uso_service.dart';
import '../../dominio/rutinas_app.dart';
import '../../dominio/rutinas_service.dart';
import '../../infraestructura/servicio_voz.dart';
import '../premios/premios_page.dart';

class RutinasPage extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onIrInicio;
  final VoidCallback? onIrFavoritos;
  final String? categoriaInicial;

  /// Abre directamente esta rutina (desde «Ir a rutina» en la cámara).
  final int? rutinaInicialId;

  const RutinasPage({
    super.key,
    this.onBack,
    this.onIrInicio,
    this.onIrFavoritos,
    this.categoriaInicial,
    this.rutinaInicialId,
  });

  @override
  State<RutinasPage> createState() => _RutinasPageState();
}

class _RutinasPageState extends State<RutinasPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorTealClaro = Color(0xFFDDE9EC);
  static const Color colorVerdeExito = Color(0xFF5E8C68);
  static const Color colorVerdeFondo = Color(0xFFE3EFE3);

  final ServicioVoz _tts = ServicioVoz();
  final TextEditingController _searchController = TextEditingController();
  final RutinasService _rutinasService = RutinasService();

  // Estados de navegación dentro de Rutinas:
  // 0: Lista de rutinas
  // 1: Resumen de pasos de la rutina
  // 2: Ejecutando paso individual
  // 3: Rutina terminada / Celebración
  int _modoVista = 0;
  bool _ganoMedalla = false; // Premios: la rutina terminada hoy dio una medalla nueva
  RutinaItem? _rutinaSeleccionada;
  int _pasoActual = 0;
  String _filtroTexto = '';
  String? _categoriaSeleccionada;

  Map<int, RutinaProgresoDia> _progresoHoy = {};
  Set<int> _desactivadas = {};

  final List<RutinaItem> _rutinas = rutinasApp;

  @override
  void initState() {
    super.initState();
    _categoriaSeleccionada = widget.categoriaInicial;
    _initTts();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prog = await _rutinasService.getProgresoHoy();
    final des = await _rutinasService.getRutinasDesactivadas();
    if (mounted) {
      setState(() {
        _progresoHoy = prog;
        _desactivadas = des;
      });
      final id = widget.rutinaInicialId;
      if (id != null && _modoVista == 0) {
        for (final r in _rutinas) {
          if (r.id == id && !des.contains(id)) {
            _seleccionarRutina(r);
            break;
          }
        }
      }
    }
  }

  /// Comenzada hoy y sin terminar: aparece primero en la lista (RF-04, US501).
  bool _enCurso(RutinaItem r) {
    final p = _progresoHoy[r.id];
    return p != null && !p.completada && p.pasoActual > 0;
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

  void _seleccionarRutina(RutinaItem rutina) {
    final prog = _progresoHoy[rutina.id];
    int pasoParaEmpezar = 0;
    if (prog != null) {
      if (prog.completada) {
        pasoParaEmpezar = 0; // Si ya completó la rutina hoy y la abre de nuevo, puede repasarla
      } else if (prog.pasoActual > 0 && prog.pasoActual < rutina.pasos.length) {
        pasoParaEmpezar = prog.pasoActual; // Reanudar exactamente en el paso guardado hoy
      }
    }

    setState(() {
      _rutinaSeleccionada = rutina;
      _modoVista = 1; // Pasos overview
      _pasoActual = pasoParaEmpezar;
    });
    _hablar('${rutina.nombre}. Tiene ${rutina.pasos.length} pasos.');
  }

  void _iniciarEjecucionPaso() {
    setState(() {
      _modoVista = 2; // Ejecutando paso individual
    });
    RegistroUsoService().registrar(RegistroUsoService.rutinaInicio, '${_rutinaSeleccionada!.id}',
        etiqueta: _rutinaSeleccionada!.nombre);
    final paso = _rutinaSeleccionada!.pasos[_pasoActual];
    _hablar('Paso ${_pasoActual + 1}: ${paso.nombre}. ${paso.fraseVoz}');
  }

  Future<void> _completarPasoActual() async {
    if (_rutinaSeleccionada == null) return;
    final total = _rutinaSeleccionada!.pasos.length;

    if (_pasoActual < total - 1) {
      final nuevoPaso = _pasoActual + 1;
      setState(() {
        _pasoActual = nuevoPaso;
      });
      RegistroUsoService().registrar(RegistroUsoService.rutinaPaso, '${_rutinaSeleccionada!.id}',
          etiqueta: _rutinaSeleccionada!.nombre);
      await _rutinasService.guardarProgreso(
        rutinaId: _rutinaSeleccionada!.id,
        pasoActual: nuevoPaso,
        completada: false,
      );
      await _cargarDatos();

      final paso = _rutinaSeleccionada!.pasos[_pasoActual];
      _hablar('Paso ${_pasoActual + 1}: ${paso.nombre}. ${paso.fraseVoz}');
    } else {
      // Premios: 1 medalla por rutina y día (si ya estaba completada hoy, no da otra)
      final yaCompletadaHoy = _progresoHoy[_rutinaSeleccionada!.id]?.completada == true;
      final premios = await PremiosService().config();
      _ganoMedalla = premios.activados && !yaCompletadaHoy;
      RegistroUsoService().registrar(RegistroUsoService.rutinaFin, '${_rutinaSeleccionada!.id}',
          etiqueta: _rutinaSeleccionada!.nombre);
      await _rutinasService.marcarCompletada(
        rutinaId: _rutinaSeleccionada!.id,
        totalPasos: total,
      );
      await _cargarDatos();

      setState(() {
        _modoVista = 3; // Pantalla de celebración
      });
      _hablar('¡Muy bien! ${_rutinaSeleccionada!.mensajeFinal}');
    }
  }

  Future<void> _volverALista() async {
    if (_rutinaSeleccionada != null) {
      final prog = _progresoHoy[_rutinaSeleccionada!.id];
      // Si la rutina no está completada pero se avanzó a un paso intermedio, guardar el paso actual
      if (prog == null || !prog.completada) {
        await _rutinasService.guardarProgreso(
          rutinaId: _rutinaSeleccionada!.id,
          pasoActual: _pasoActual,
          completada: false,
        );
      }
    }
    await _cargarDatos();
    setState(() {
      _modoVista = 0;
      _rutinaSeleccionada = null;
      _pasoActual = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget contenido;
    switch (_modoVista) {
      case 1:
        contenido = _buildVistaResumenPasos();
        break;
      case 2:
        contenido = _buildVistaPasoActual();
        break;
      case 3:
        contenido = _buildVistaTerminada();
        break;
      default:
        contenido = _buildVistaListaRutinas();
    }

    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: contenido),
            _buildBarraInferior(),
          ],
        ),
      ),
    );
  }

  // Vista 1: lista de rutinas
  Widget _buildVistaListaRutinas() {
    final rutinasActivas = _rutinas.where((r) => !_desactivadas.contains(r.id)).toList();

    final rutinasFiltradas = rutinasActivas.where((r) {
      if (_categoriaSeleccionada != null && r.categoria != _categoriaSeleccionada) {
        return false;
      }
      if (_filtroTexto.trim().isNotEmpty &&
          !r.nombre.toLowerCase().contains(_filtroTexto.trim().toLowerCase())) {
        return false;
      }
      return true;
    }).toList()
      // Las comenzadas hoy y sin terminar van primero (sort estable: el resto mantiene su orden)
      ..sort((a, b) => (_enCurso(b) ? 1 : 0) - (_enCurso(a) ? 1 : 0));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBotonVolver(onTap: widget.onBack ?? () => Navigator.maybePop(context)),
              const SizedBox(width: 14),
              Text(
                _categoriaSeleccionada != null ? 'Rutinas · $_categoriaSeleccionada' : 'Rutinas',
                style: const TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Elige qué rutina vas a hacer.',
            style: TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colorTextoSecundario,
            ),
          ),
          const SizedBox(height: 14),

          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEFEAE1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorBorde, width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF8E887C), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _filtroTexto = val),
                    style: const TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 15,
                      color: colorTextoPrincipal,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Buscar rutina',
                      hintStyle: TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 15,
                        color: Color(0xFF8E887C),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildCategoriaChip(
                  label: 'Todas',
                  seleccionada: _categoriaSeleccionada == null,
                  onTap: () => setState(() => _categoriaSeleccionada = null),
                ),
                _buildCategoriaChip(
                  label: 'Higiene',
                  seleccionada: _categoriaSeleccionada == 'Higiene',
                  onTap: () => setState(() => _categoriaSeleccionada = 'Higiene'),
                ),
                _buildCategoriaChip(
                  label: 'Ropa',
                  seleccionada: _categoriaSeleccionada == 'Ropa',
                  onTap: () => setState(() => _categoriaSeleccionada = 'Ropa'),
                ),
                _buildCategoriaChip(
                  label: 'Comida',
                  seleccionada: _categoriaSeleccionada == 'Comida',
                  onTap: () => setState(() => _categoriaSeleccionada = 'Comida'),
                ),
                _buildCategoriaChip(
                  label: 'Hogar',
                  seleccionada: _categoriaSeleccionada == 'Hogar',
                  onTap: () => setState(() => _categoriaSeleccionada = 'Hogar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: rutinasFiltradas.isEmpty
                ? const Center(
                    child: Text(
                      'No hay rutinas disponibles en esta categoría.',
                      style: TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 14,
                        color: colorTextoSecundario,
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: rutinasFiltradas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final r = rutinasFiltradas[index];
                      return _buildTarjetaRutina(r);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaChip({
    required String label,
    required bool seleccionada,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: seleccionada ? colorTealPrimario : const Color(0xFFF2ECE4),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: seleccionada ? colorTealPrimario : colorBorde,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 13,
              fontWeight: seleccionada ? FontWeight.w700 : FontWeight.w500,
              color: seleccionada ? Colors.white : colorTextoPrincipal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTarjetaRutina(RutinaItem r) {
    final prog = _progresoHoy[r.id];
    final bool completada = prog?.completada ?? false;
    final int pasosHechos = prog?.pasoActual ?? 0;
    final int totalPasos = r.pasos.length;

    final double ratio = completada
        ? 1.0
        : (totalPasos > 0 ? (pasosHechos / totalPasos).clamp(0.0, 1.0) : 0.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _seleccionarRutina(r),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 98,
          decoration: BoxDecoration(
            color: completada ? const Color(0xFFF2F8F2) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: completada ? const Color(0xFFBFD9BE) : colorTealPrimario,
              width: 2.0,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorVerdeFondo,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Image.asset(
                    r.assetIcono,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.cleaning_services_rounded,
                      color: colorTealPrimario,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      r.nombre,
                      style: const TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colorTextoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 164,
                        height: 8,
                        color: const Color(0xFFEDE8E0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 164 * ratio,
                            color: completada ? colorVerdeExito : colorTealPrimario,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      completada
                          ? '$totalPasos de $totalPasos pasos'
                          : (_enCurso(r)
                              ? 'CONTINUAR · $pasosHechos de $totalPasos pasos'
                              : '$pasosHechos de $totalPasos pasos'),
                      style: TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: completada ? colorVerdeExito : colorTextoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              completada
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: colorVerdeExito,
                      size: 28,
                    )
                  : const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: colorTextoSecundario,
                      size: 18,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Vista 2: resumen de pasos
  Widget _buildVistaResumenPasos() {
    final r = _rutinaSeleccionada!;
    final total = r.pasos.length;
    final prog = _progresoHoy[r.id];
    final bool completada = prog?.completada ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBotonVolver(onTap: _volverALista),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  r.nombre,
                  style: const TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: colorTextoPrincipal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                completada
                    ? '$total de $total pasos'
                    : '$_pasoActual de $total pasos',
                style: const TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorVerdeExito,
                ),
              ),
              Text(
                completada
                    ? '¡Rutina cumplida hoy!'
                    : (_pasoActual > 0
                        ? 'Paso ${_pasoActual + 1} de $total'
                        : '¡Vamos a empezar!'),
                style: const TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colorTextoSecundario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 9,
              color: const Color(0xFFEDE8E0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: total > 0
                      ? (MediaQuery.of(context).size.width - 48) *
                          (completada ? 1.0 : (_pasoActual / total).clamp(0.0, 1.0))
                      : 0,
                  color: completada ? colorVerdeExito : colorTealPrimario,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: r.pasos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final paso = r.pasos[index];
                final bool pasoYaHecho = index < _pasoActual || completada;
                final bool esPasoActivo = index == _pasoActual && !completada;

                return Container(
                  height: 78,
                  decoration: BoxDecoration(
                    color: esPasoActivo
                        ? colorTealClaro
                        : (pasoYaHecho ? const Color(0xFFF2F8F2) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: esPasoActivo
                          ? colorTealPrimario
                          : (pasoYaHecho ? const Color(0xFFBFD9BE) : colorBorde),
                      width: esPasoActivo ? 2.5 : 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: esPasoActivo ? Colors.white : const Color(0xFFF4F1EC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Center(
                          child: Image.asset(
                            paso.archivoPictograma,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.task_alt_rounded,
                              color: colorTealPrimario,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              esPasoActivo ? 'AHORA' : (pasoYaHecho ? 'LISTO' : '${paso.numero}'),
                              style: TextStyle(
                                fontFamily: 'Atkinson Hyperlegible Next',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: esPasoActivo
                                    ? colorTealPrimario
                                    : (pasoYaHecho ? colorVerdeExito : colorTextoSecundario),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              paso.nombre,
                              style: const TextStyle(
                                fontFamily: 'Atkinson Hyperlegible Next',
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: colorTextoPrincipal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (pasoYaHecho)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: colorVerdeExito,
                          size: 26,
                        )
                      else if (esPasoActivo)
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: colorTealPrimario,
                          size: 28,
                        )
                      else
                        const Icon(
                          Icons.radio_button_unchecked_rounded,
                          color: colorBorde,
                          size: 26,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _iniciarEjecucionPaso,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTealPrimario,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _pasoActual == 0
                    ? '¡Empezar!'
                    : (_pasoActual < r.pasos.length
                        ? 'Continuar en paso ${_pasoActual + 1}'
                        : 'Volver a hacer rutina'),
                style: const TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Vista 3: paso actual
  Widget _buildVistaPasoActual() {
    final r = _rutinaSeleccionada!;
    final paso = r.pasos[_pasoActual];
    final siguientePaso = _pasoActual < r.pasos.length - 1 ? r.pasos[_pasoActual + 1] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBotonVolver(
                onTap: () async {
                  if (_pasoActual > 0) {
                    setState(() => _pasoActual--);
                    await _rutinasService.guardarProgreso(
                      rutinaId: r.id,
                      pasoActual: _pasoActual,
                      completada: false,
                    );
                  } else {
                    setState(() => _modoVista = 1);
                  }
                },
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  r.nombre,
                  style: const TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: colorTextoPrincipal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: colorTealClaro,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'AHORA',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorTealPrimario,
                        ),
                      ),
                      Text(
                        paso.nombreCorto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorTextoPrincipal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F1EC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'DESPUÉS',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorTextoSecundario,
                        ),
                      ),
                      Text(
                        siguientePaso != null ? siguientePaso.nombreCorto : '¡Listo!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorTextoPrincipal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorTealPrimario, width: 2),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        paso.archivoPictograma,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          r.assetIcono,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    paso.nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colorTextoPrincipal,
                    ),
                  ),
                  // Temporizador opcional del paso (RF-04, US504)
                  if (paso.segundos != null) ...[
                    const SizedBox(height: 14),
                    _TemporizadorPaso(
                      key: ValueKey('temporizador-${r.id}-$_pasoActual'),
                      segundos: paso.segundos!,
                      onListo: () => _hablar('¡Listo! Toca terminé.'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => _hablar('${paso.nombre}. ${paso.fraseVoz}'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: colorBorde, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volume_up_rounded, color: colorTealPrimario, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Escuchar',
                    style: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorTealPrimario,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _completarPasoActual,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTealPrimario,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _pasoActual == r.pasos.length - 1 ? '¡Terminé la rutina!' : '¡Terminé este paso!',
                style: const TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Vista 4: rutina terminada
  Widget _buildVistaTerminada() {
    final r = _rutinaSeleccionada!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBotonVolver(onTap: _volverALista),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  r.nombre,
                  style: const TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: colorTextoPrincipal,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Image.asset(
            'assets/images/rut_insignia_terminado.png',
            // Con la tarjeta de medalla, la insignia se achica a 92 para que todo quepa
            width: _ganoMedalla ? 92 : 124,
            height: _ganoMedalla ? 92 : 124,
            errorBuilder: (_, __, ___) => Container(
              width: _ganoMedalla ? 92 : 124,
              height: _ganoMedalla ? 92 : 124,
              decoration: const BoxDecoration(
                color: Color(0xFFC7DBC5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 72),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '¡Muy bien!',
            style: TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colorTextoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            r.mensajeFinal,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: colorTextoSecundario,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(r.pasos.length, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3EFE3),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check_rounded, color: colorVerdeExito, size: 22),
                ),
              );
            }),
          ),
          if (_ganoMedalla) ...[
            const SizedBox(height: 28),
            Semantics(
              label: '¡Ganaste una medalla!',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  border: Border.all(color: const Color(0xFFF1DFA0), width: 2),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    medallaGanada(88),
                    const SizedBox(height: 12),
                    const Text(
                      '¡Ganaste una medalla!',
                      style: TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: colorTextoPrincipal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: 'Ver mis premios',
              child: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MisPremiosPage(
                    onIrInicio: widget.onIrInicio,
                    onIrFavoritos: widget.onIrFavoritos,
                  ),
                )),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver mis premios',
                      style: TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorTealPrimario,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded, color: colorTealPrimario, size: 22),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _volverALista,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTealPrimario,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Volver a mis rutinas',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildBotonVolver({required VoidCallback onTap}) {
    return Semantics(button: true, label: 'Volver', child: InkWell(
      onTap: onTap,
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
          child: Icon(Icons.arrow_back_rounded, color: colorTextoPrincipal, size: 22),
        ),
      ),
    ));
  }

  Widget _buildBarraInferior() {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEDE8E0), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: widget.onIrInicio ?? () => Navigator.maybePop(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.home_rounded, color: colorTealPrimario, size: 24),
                  SizedBox(height: 4),
                  Text(
                    'Inicio',
                    style: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorTealPrimario,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: widget.onIrFavoritos ?? () => Navigator.maybePop(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.star_outline_rounded, color: colorTextoSecundario, size: 24),
                  SizedBox(height: 4),
                  Text(
                    'Favoritos',
                    style: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorTextoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pantalla «Empieza con…»: el objeto que vio la cámara y las rutinas activas que empiezan con él.
/// Es distinta de la lista normal de Rutinas (que va por categorías): aquí ya viene filtrada.
class RutinasConObjetoPage extends StatefulWidget {
  final String nombreObjeto;
  final String assetObjeto;
  final List<RutinaItem> rutinas;

  const RutinasConObjetoPage({
    super.key,
    required this.nombreObjeto,
    required this.assetObjeto,
    required this.rutinas,
  });

  @override
  State<RutinasConObjetoPage> createState() => _RutinasConObjetoPageState();
}

class _RutinasConObjetoPageState extends State<RutinasConObjetoPage> {
  static const Color _teal = Color(0xFF3D6D7E);
  static const Color _tealClaro = Color(0xFFDDE9EC);
  static const Color _texto = Color(0xFF3A3A3A);
  static const Color _textoSecundario = Color(0xFF6B6B66);
  Map<int, RutinaProgresoDia> _progreso = {};

  @override
  void initState() {
    super.initState();
    RutinasService().getProgresoHoy().then((p) {
      if (mounted) setState(() => _progreso = p);
    });
  }

  bool _enCurso(RutinaItem r) {
    final p = _progreso[r.id];
    return p != null && !p.completada && p.pasoActual > 0;
  }

  @override
  Widget build(BuildContext context) {
    final lista = List<RutinaItem>.from(widget.rutinas)
      ..sort((a, b) => (_enCurso(b) ? 1 : 0) - (_enCurso(a) ? 1 : 0));
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Volver',
                    child: InkWell(
                      onTap: () => Navigator.maybePop(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(color: _tealClaro, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_rounded, color: _teal),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Empieza con…',
                      style: TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _texto,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF8F2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5A93C), width: 2.5),
                      ),
                      child: Image.asset(
                        widget.assetObjeto,
                        fit: BoxFit.contain,
                        semanticLabel: widget.nombreObjeto,
                        errorBuilder: (_, __, ___) => const Icon(Icons.category, size: 48, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.nombreObjeto,
                      style: const TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _texto,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lista.length == 1 ? 'Con esto empieza 1 rutina' : 'Con esto empiezan ${lista.length} rutinas',
                      style: const TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 14,
                        color: _textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final r = lista[i];
                    final hecha = _progreso[r.id]?.completada ?? false;
                    final enCurso = _enCurso(r);
                    final accion = hecha ? 'Hecha hoy' : (enCurso ? 'Continuar' : 'Empezar');
                    return Semantics(
                      button: true,
                      label: '${r.nombre}. $accion',
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => RutinasPage(rutinaInicialId: r.id)),
                        ),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: hecha ? const Color(0xFFF2F8F2) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFDDD6C9), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                r.assetIcono,
                                width: 52,
                                height: 52,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.checklist_rounded, color: _teal, size: 36),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.nombre,
                                      style: const TextStyle(
                                        fontFamily: 'Atkinson Hyperlegible Next',
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: _texto,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${r.pasos.length} pasos · ${r.categoria}',
                                      style: const TextStyle(
                                        fontFamily: 'Atkinson Hyperlegible Next',
                                        fontSize: 13,
                                        color: _textoSecundario,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: enCurso ? _teal : _tealClaro,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  accion,
                                  style: TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: enCurso ? Colors.white : _teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
}

/// Temporizador de un paso de rutina (RF-04, US504): cuenta regresiva que arranca sola,
/// se puede pausar y al llegar a cero muestra «¡Listo!». No bloquea «¡Terminé!»:
/// el paso espera a que el niño lo toque.
class _TemporizadorPaso extends StatefulWidget {
  final int segundos;
  final VoidCallback onListo;
  const _TemporizadorPaso({super.key, required this.segundos, required this.onListo});

  @override
  State<_TemporizadorPaso> createState() => _TemporizadorPasoState();
}

class _TemporizadorPasoState extends State<_TemporizadorPaso> {
  static const Color _teal = Color(0xFF3D6D7E);
  static const Color _verde = Color(0xFF4E8A57);
  Timer? _reloj;
  late int _restantes;
  bool _pausado = false;

  bool get _listo => _restantes <= 0;

  @override
  void initState() {
    super.initState();
    _restantes = widget.segundos;
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) => _tic());
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  void _tic() {
    if (!mounted || _pausado || _listo) return;
    setState(() => _restantes--);
    if (_listo) {
      _reloj?.cancel();
      AccesibilidadService().feedbackInteraccion();
      widget.onListo();
    }
  }

  void _alternarPausa() {
    if (_listo) return;
    setState(() => _pausado = !_pausado);
  }

  void _reiniciar() {
    _reloj?.cancel();
    setState(() {
      _restantes = widget.segundos;
      _pausado = false;
    });
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) => _tic());
  }

  String get _texto {
    final m = _restantes ~/ 60;
    final ss = (_restantes % 60).toString().padLeft(2, '0');
    return m > 0 ? '$m:$ss' : '$_restantes';
  }

  @override
  Widget build(BuildContext context) {
    final progreso = widget.segundos == 0 ? 1.0 : 1 - _restantes / widget.segundos;
    return Semantics(
      liveRegion: true,
      label: _listo ? '¡Listo!' : 'Faltan $_restantes segundos',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: progreso.clamp(0.0, 1.0),
                    strokeWidth: 6,
                    backgroundColor: const Color(0xFFE3EFE3),
                    valueColor: AlwaysStoppedAnimation(_listo ? _verde : _teal),
                  ),
                ),
                _listo
                    ? const Icon(Icons.check_rounded, color: _verde, size: 34)
                    : Text(_texto,
                        style: const TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _teal,
                        )),
              ],
            ),
          ),
          const SizedBox(width: 14),
          if (_listo)
            const Text('¡Listo!',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _verde,
                ))
          else ...[
            Semantics(
              button: true,
              label: _pausado ? 'Seguir' : 'Pausar',
              child: IconButton.outlined(
                onPressed: _alternarPausa,
                icon: Icon(_pausado ? Icons.play_arrow_rounded : Icons.pause_rounded, color: _teal),
              ),
            ),
            Semantics(
              button: true,
              label: 'Empezar de nuevo',
              child: IconButton(
                onPressed: _reiniciar,
                icon: const Icon(Icons.replay_rounded, color: _teal),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
