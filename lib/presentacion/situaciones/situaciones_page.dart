import 'package:flutter/material.dart';

import '../../infraestructura/servicio_voz.dart';

class PasoHistoriaSocial {
  final String texto;
  final String? imagenAsset;

  const PasoHistoriaSocial({
    required this.texto,
    this.imagenAsset,
  });
}

class SituacionClinica {
  final String id;
  final String titulo;
  final String grupo;
  final Color colorGrupo;
  final String assetIcono;
  final String mensajeFinal;
  final List<PasoHistoriaSocial> pasos;

  const SituacionClinica({
    required this.id,
    required this.titulo,
    required this.grupo,
    required this.colorGrupo,
    required this.assetIcono,
    required this.mensajeFinal,
    required this.pasos,
  });
}

class SituacionesPage extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onIrInicio;
  final VoidCallback? onIrFavoritos;

  const SituacionesPage({
    super.key,
    this.onBack,
    this.onIrInicio,
    this.onIrFavoritos,
  });

  @override
  State<SituacionesPage> createState() => _SituacionesPageState();
}

class _SituacionesPageState extends State<SituacionesPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorTealClaro = Color(0xFFDDE9EC);
  static const Color colorVerdeExito = Color(0xFFC7DBC5);

  final ServicioVoz _tts = ServicioVoz();

  // Estado de navegación:
  // null = pantalla de lista
  // non-null = viendo pasos o pantalla final
  SituacionClinica? _situacionActiva;
  int _pasoActual = 0; // 0-indexed
  bool _mostrarFinal = false;

  static const Color colorGrupoSeguro = Color(0xFF3D6D7E);
  static const Color colorGrupoDificil = Color(0xFF7C6BA0);
  static const Color colorGrupoSocial = Color(0xFF5E8C68);

  final List<SituacionClinica> _situaciones = const [
    // 1. Para estar seguro
    SituacionClinica(
      id: 'cruzar_calle',
      titulo: 'Cruzar la calle',
      grupo: 'Para estar seguro',
      colorGrupo: colorGrupoSeguro,
      assetIcono: 'assets/images/sit_cruzar_calle.png',
      mensajeFinal: 'Ya sabes cómo cruzar la calle.',
      pasos: [
        PasoHistoriaSocial(
          texto: 'Voy a cruzar la calle con un adulto.',
          imagenAsset: 'assets/images/situaciones/sit_cruzar_calle_1.png',
        ),
        PasoHistoriaSocial(
          texto: 'Me paro en la vereda, detrás de la línea.',
          imagenAsset: 'assets/images/situaciones/sit_cruzar_calle_2.png',
        ),
        PasoHistoriaSocial(
          texto: 'Miro a la izquierda y a la derecha.',
          imagenAsset: 'assets/images/situaciones/sit_cruzar_calle_3.png',
        ),
        PasoHistoriaSocial(
          texto: 'Con luz roja espero. Con luz verde, camino.',
          imagenAsset: 'assets/images/situaciones/sit_cruzar_calle_4.png',
        ),
        PasoHistoriaSocial(
          texto: 'Cruzo caminando, de la mano de un adulto.',
          imagenAsset: 'assets/images/situaciones/sit_cruzar_calle_5.png',
        ),
        PasoHistoriaSocial(
          texto: 'Llegué a la otra vereda. ¡Lo hice muy bien!',
          imagenAsset: 'assets/images/situaciones/sit_cruzar_calle_6.png',
        ),
      ],
    ),
    SituacionClinica(
      id: 'si_me_pierdo',
      titulo: 'Si me pierdo',
      grupo: 'Para estar seguro',
      colorGrupo: colorGrupoSeguro,
      assetIcono: 'assets/images/sit_si_me_pierdo.png',
      mensajeFinal: 'Ya sabes qué hacer si te pierdes.',
      pasos: [
        PasoHistoriaSocial(
          texto: 'Si me separo de mi familia, sé qué hacer.',
          imagenAsset: 'assets/images/situaciones/sit_si_me_pierdo_1.png',
        ),
        PasoHistoriaSocial(
          texto: 'Me quedo quieto y respiro despacito.',
          imagenAsset: 'assets/images/situaciones/sit_si_me_pierdo_2.png',
        ),
        PasoHistoriaSocial(
          texto: 'Busco a un policía o a alguien con uniforme.',
          imagenAsset: 'assets/images/situaciones/sit_si_me_pierdo_3.png',
        ),
        PasoHistoriaSocial(
          texto: 'Le digo mi nombre y que me perdí.',
          imagenAsset: 'assets/images/situaciones/sit_si_me_pierdo_4.png',
        ),
        PasoHistoriaSocial(
          texto: 'Espero con esa persona hasta que llegue mi familia.',
          imagenAsset: 'assets/images/situaciones/sit_si_me_pierdo_5.png',
        ),
        PasoHistoriaSocial(
          texto: 'Mi familia me encuentra. ¡Qué alegría!',
          imagenAsset: 'assets/images/situaciones/sit_si_me_pierdo_6.png',
        ),
      ],
    ),

    // 2. Cuando es difícil
    SituacionClinica(
      id: 'doctor',
      titulo: 'Ir al doctor',
      grupo: 'Cuando es difícil',
      colorGrupo: colorGrupoDificil,
      assetIcono: 'assets/images/sit_doctor.png',
      mensajeFinal: 'Ya sabes cómo es ir al doctor.',
      pasos: [
        PasoHistoriaSocial(
          texto: 'Hoy voy al doctor para cuidar mi cuerpo.',
          imagenAsset: 'assets/images/situaciones/sit_doctor_1.png',
        ),
        PasoHistoriaSocial(
          texto: 'Espero mi turno con un adulto.',
          imagenAsset: 'assets/images/situaciones/sit_doctor_2.png',
        ),
        PasoHistoriaSocial(
          texto: 'El doctor me saluda y me cuenta qué va a hacer.',
          imagenAsset: 'assets/images/situaciones/sit_doctor_3.png',
        ),
        PasoHistoriaSocial(
          texto: 'El doctor me escucha el corazón.',
          imagenAsset: 'assets/images/situaciones/sit_doctor_4.png',
        ),
        PasoHistoriaSocial(
          texto: 'Si algo me molesta, puedo decir «pausa».',
          imagenAsset: 'assets/images/situaciones/sit_doctor_5.png',
        ),
        PasoHistoriaSocial(
          texto: 'Terminé. ¡Fui muy valiente!',
          imagenAsset: 'assets/images/situaciones/sit_doctor_6.png',
        ),
      ],
    ),
    SituacionClinica(
      id: 'mucho_ruido',
      titulo: 'Cuando hay mucho ruido',
      grupo: 'Cuando es difícil',
      colorGrupo: colorGrupoDificil,
      assetIcono: 'assets/images/sit_mucho_ruido.png',
      mensajeFinal: 'Ya sabes qué hacer con los ruidos fuertes.',
      pasos: [
        PasoHistoriaSocial(
          texto: 'A veces hay ruidos muy fuertes, como una sirena.',
          imagenAsset: 'assets/images/situaciones/sit_mucho_ruido_1.png',
        ),
        PasoHistoriaSocial(
          texto: 'Mis oídos se sienten incómodos. Es normal.',
          imagenAsset: 'assets/images/situaciones/sit_mucho_ruido_2.png',
        ),
        PasoHistoriaSocial(
          texto: 'Le aviso a un adulto: «Me molesta el ruido».',
          imagenAsset: 'assets/images/situaciones/sit_mucho_ruido_3.png',
        ),
        PasoHistoriaSocial(
          texto: 'Me voy con el adulto a un lugar más tranquilo.',
          imagenAsset: 'assets/images/situaciones/sit_mucho_ruido_4.png',
        ),
        PasoHistoriaSocial(
          texto: 'Respiro despacito. Si quiero, uso mis audífonos.',
          imagenAsset: 'assets/images/situaciones/sit_mucho_ruido_5.png',
        ),
        PasoHistoriaSocial(
          texto: 'Cuando me siento mejor, puedo volver.',
          imagenAsset: 'assets/images/situaciones/sit_mucho_ruido_6.png',
        ),
      ],
    ),

    // 3. Con otras personas
    SituacionClinica(
      id: 'saludar',
      titulo: 'Saludar',
      grupo: 'Con otras personas',
      colorGrupo: colorGrupoSocial,
      assetIcono: 'assets/images/sit_saludar.png',
      mensajeFinal: 'Ya sabes cómo saludar.',
      pasos: [
        PasoHistoriaSocial(
          texto: 'Veo a una persona que conozco.',
          imagenAsset: 'assets/images/situaciones/sit_saludar_1.png',
        ),
        PasoHistoriaSocial(
          texto: 'Por la mañana digo «Buenos días».',
          imagenAsset: 'assets/images/situaciones/sit_saludar_2.png',
        ),
        PasoHistoriaSocial(
          texto: 'Por la tarde digo «Buenas tardes».',
          imagenAsset: 'assets/images/situaciones/sit_saludar_3.png',
        ),
        PasoHistoriaSocial(
          texto: 'Por la noche digo «Buenas noches».',
          imagenAsset: 'assets/images/situaciones/sit_saludar_4.png',
        ),
        PasoHistoriaSocial(
          texto: 'Espero un momento a que me responda.',
          imagenAsset: 'assets/images/situaciones/sit_saludar_5.png',
        ),
        PasoHistoriaSocial(
          texto: 'Cuando termino, digo «Adiós».',
          imagenAsset: 'assets/images/situaciones/sit_saludar_6.png',
        ),
      ],
    ),
    SituacionClinica(
      id: 'jugar_ninos',
      titulo: 'Jugar con otros niños',
      grupo: 'Con otras personas',
      colorGrupo: colorGrupoSocial,
      assetIcono: 'assets/images/sit_jugar_ninos.png',
      mensajeFinal: 'Ya sabes cómo jugar con otros niños.',
      pasos: [
        PasoHistoriaSocial(
          texto: 'Veo a otros niños jugando.',
          imagenAsset: 'assets/images/situaciones/sit_jugar_ninos_1.png',
        ),
        PasoHistoriaSocial(
          texto: 'Me acerco y pregunto: «¿Puedo jugar?»',
          imagenAsset: 'assets/images/situaciones/sit_jugar_ninos_2.png',
        ),
        PasoHistoriaSocial(
          texto: 'Si dicen que sí, juego con ellos.',
          imagenAsset: 'assets/images/situaciones/sit_jugar_ninos_3.png',
        ),
        PasoHistoriaSocial(
          texto: 'Si dicen que no, busco otro juego.',
          imagenAsset: 'assets/images/situaciones/sit_jugar_ninos_4.png',
        ),
        PasoHistoriaSocial(
          texto: 'Mientras juego, comparto y espero mi turno.',
          imagenAsset: 'assets/images/situaciones/sit_jugar_ninos_5.png',
        ),
        PasoHistoriaSocial(
          texto: 'Al terminar, digo «Gracias por jugar».',
          imagenAsset: 'assets/images/situaciones/sit_jugar_ninos_6.png',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
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

  void _seleccionarSituacion(SituacionClinica sit) {
    setState(() {
      _situacionActiva = sit;
      _pasoActual = 0;
      _mostrarFinal = false;
    });
    _hablar('${sit.titulo}. ${sit.pasos.first.texto}');
  }

  void _volverALista() {
    setState(() {
      _situacionActiva = null;
      _pasoActual = 0;
      _mostrarFinal = false;
    });
  }

  void _avanzarPaso() {
    if (_situacionActiva == null) return;
    if (_pasoActual < _situacionActiva!.pasos.length - 1) {
      setState(() {
        _pasoActual++;
      });
      _hablar(_situacionActiva!.pasos[_pasoActual].texto);
    } else {
      setState(() {
        _mostrarFinal = true;
      });
      _hablar('¡Muy bien! ${_situacionActiva!.mensajeFinal}');
    }
  }

  void _retrocederPaso() {
    if (_pasoActual > 0) {
      setState(() {
        _pasoActual--;
      });
      _hablar(_situacionActiva!.pasos[_pasoActual].texto);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _situacionActiva == null
                  ? _buildVistaLista()
                  : _mostrarFinal
                      ? _buildVistaFinal()
                      : _buildVistaPaso(),
            ),
            _buildBarraInferior(),
          ],
        ),
      ),
    );
  }

  // Vista 1: lista de situaciones por grupos clínicos (Figma 586:2)
  Widget _buildVistaLista() {
    // Agrupar situaciones
    final Map<String, List<SituacionClinica>> grupos = {};
    for (final s in _situaciones) {
      grupos.putIfAbsent(s.grupo, () => []).add(s);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBotonVolver(onTap: widget.onBack ?? () => Navigator.maybePop(context)),
              const SizedBox(width: 14),
              const Text(
                'Situaciones',
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
          const Text(
            '¿Qué quieres repasar?',
            style: TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorTextoPrincipal,
            ),
          ),
          const SizedBox(height: 16),
          for (final entry in grupos.entries) ...[
            _buildEncabezadoGrupo(entry.key, entry.value.first.colorGrupo),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildTarjetaSituacion(entry.value[0])),
                const SizedBox(width: 12),
                Expanded(
                  child: entry.value.length > 1
                      ? _buildTarjetaSituacion(entry.value[1])
                      : const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildEncabezadoGrupo(String titulo, Color colorPunto) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: colorPunto,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colorTextoPrincipal,
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaSituacion(SituacionClinica sit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _seleccionarSituacion(sit),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 122,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: colorFondo,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorTealPrimario, width: 2.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                sit.assetIcono,
                width: 56,
                height: 56,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.storefront_rounded,
                  size: 48,
                  color: colorTealPrimario,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sit.titulo,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Vista 2: paso a paso
  Widget _buildVistaPaso() {
    final sit = _situacionActiva!;
    final totalPasos = sit.pasos.length;
    final paso = sit.pasos[_pasoActual];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBotonVolver(
                onTap: _pasoActual == 0 ? _volverALista : _retrocederPaso,
              ),
              const SizedBox(width: 14),
              Text(
                sit.titulo,
                style: const TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'PASO ${_pasoActual + 1} DE $totalPasos',
              style: const TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorTealPrimario,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildBarraProgresoSegmentada(totalPasos, _pasoActual),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF5EEDD),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE6DAB8), width: 2),
              ),
              padding: const EdgeInsets.all(20),
              child: Center(
                child: paso.imagenAsset != null
                    ? Image.asset(
                        paso.imagenAsset!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          sit.assetIcono,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Image.asset(sit.assetIcono, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  paso.texto,
                  style: const TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colorTextoPrincipal,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Semantics(button: true, label: 'Escuchar', child: InkWell(
                onTap: () => _hablar(paso.texto),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: colorTealClaro,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: colorTealPrimario,
                      size: 28,
                    ),
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: 20),
          _pasoActual == 0
              // Paso 1: Sólo botón "Siguiente" full width
              ? SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _avanzarPaso,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorTealPrimario,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Siguiente',
                          style: TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                )
              // Paso 2+: Botón "Atrás" (96px) + "Siguiente" (expandido)
              : Row(
                  children: [
                    SizedBox(
                      width: 96,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _retrocederPaso,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: colorBorde, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: colorTextoPrincipal,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _avanzarPaso,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorTealPrimario,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _pasoActual == totalPasos - 1 ? 'Terminar' : 'Siguiente',
                                style: const TextStyle(
                                  fontFamily: 'Atkinson Hyperlegible Next',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Vista 3: final
  Widget _buildVistaFinal() {
    final sit = _situacionActiva!;

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
              Text(
                sit.titulo,
                style: const TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 176,
            height: 176,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorVerdeExito, width: 3),
            ),
            child: Center(
              child: Container(
                width: 154,
                height: 154,
                decoration: const BoxDecoration(
                  color: colorVerdeExito,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/sit_check_circle.png',
                    width: 96,
                    height: 96,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.check_rounded,
                      size: 96,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Muy bien!',
            style: TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: colorTextoPrincipal,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              sit.mensajeFinal,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: colorTextoSecundario,
                height: 1.3,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _pasoActual = 0;
                  _mostrarFinal = false;
                });
                _hablar('${sit.titulo}. ${sit.pasos.first.texto}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTealPrimario,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.replay_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Leer otra vez',
                    style: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _volverALista,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: colorBorde, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Otra situación',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorTealPrimario,
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

  Widget _buildBarraProgresoSegmentada(int total, int actual) {
    return Row(
      children: List.generate(total, (i) {
        final activo = i <= actual;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i < total - 1 ? 6.0 : 0.0),
            decoration: BoxDecoration(
              color: activo ? colorTealPrimario : const Color(0xFFEDE8E0),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
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
              onTap: widget.onIrFavoritos ??
                  () {
                    Navigator.maybePop(context);
                  },
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
