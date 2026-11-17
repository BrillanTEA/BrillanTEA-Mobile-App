import 'package:flutter/material.dart';

import '../../dominio/accesibilidad_service.dart';
import '../../dominio/comunicacion_data.dart';
import '../../dominio/favoritos_service.dart';
import '../../dominio/registro_uso_service.dart';
import '../../infraestructura/servicio_voz.dart';

/// Módulo Comunicación: Pedir algo, Armar mi frase y Responder (sí o no).
class ComunicacionPage extends StatefulWidget {
  final VoidCallback? onBack;

  const ComunicacionPage({super.key, this.onBack});

  @override
  State<ComunicacionPage> createState() => _ComunicacionPageState();
}

enum _SubPantallaComunicacion {
  menu,
  pedirAlgo,
  subPedidoComer,
  subPedidoTomar,
  subPedidoJugar,
  armarFrase,
  responder,
}

class ElementoPedido {
  final String id;
  final String titulo;
  final String subtitulo;
  final String fraseVoz;
  final String assetIcon;
  final Color? colorDot;

  const ElementoPedido({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.fraseVoz,
    required this.assetIcon,
    this.colorDot,
  });
}

class _ComunicacionPageState extends State<ComunicacionPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);

  final ServicioVoz _tts = ServicioVoz();
  final FavoritosService _favoritosService = FavoritosService();


  _SubPantallaComunicacion _pantallaActual = _SubPantallaComunicacion.menu;

  // Estados para "Armar mi frase"
  int _pasoFrase = 1; // 1: verbo, 2: categoría, 3: pictograma, 4: frase lista
  VerboFrase _verbo = verbosFrase.first;
  OpcionComunicacion? _categoria;
  OpcionComunicacion? _objeto;

  @override
  void initState() {
    super.initState();
    _initTts();
    _favoritosService.init();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }  Future<void> _initTts() async {
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
    if (_pantallaActual == _SubPantallaComunicacion.armarFrase) {
      if (_pasoFrase > 1) {
        setState(_retrocederPasoFrase);
        return;
      }
    }
    if (_pantallaActual == _SubPantallaComunicacion.subPedidoComer ||
        _pantallaActual == _SubPantallaComunicacion.subPedidoTomar ||
        _pantallaActual == _SubPantallaComunicacion.subPedidoJugar) {
      setState(() => _pantallaActual = _SubPantallaComunicacion.pedirAlgo);
      return;
    }
    if (_pantallaActual != _SubPantallaComunicacion.menu) {
      setState(() => _pantallaActual = _SubPantallaComunicacion.menu);
      return;
    }
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_pantallaActual) {
      case _SubPantallaComunicacion.menu:
        return _buildMenuPrincipal();
      case _SubPantallaComunicacion.responder:
        return _buildResponderScreen();
      case _SubPantallaComunicacion.pedirAlgo:
        return _buildPedirAlgoScreen();
      case _SubPantallaComunicacion.subPedidoComer:
        return _buildSubOpcionesPedido(
          titulo: 'Comer',
          pregunta: '¿Qué quieres comer?',
          opciones: pedidosComer,
        );
      case _SubPantallaComunicacion.subPedidoTomar:
        return _buildSubOpcionesPedido(
          titulo: 'Tomar',
          pregunta: '¿Qué quieres tomar?',
          opciones: pedidosTomar,
        );
      case _SubPantallaComunicacion.subPedidoJugar:
        return _buildSubOpcionesPedido(
          titulo: 'Jugar',
          pregunta: '¿A qué quieres jugar?',
          opciones: pedidosJugar,
        );
      case _SubPantallaComunicacion.armarFrase:
        return _buildArmarFraseScreen();
    }
  }

  // Menú
  Widget _buildMenuPrincipal() {
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
                'Comunicación',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '¿Qué quieres hacer?',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
              const SizedBox(height: 18),

              _buildCardMenu(
                titulo: 'Pedir algo',
                subtitulo: 'Comer, tomar, baño, ayuda…',
                assetIcon: 'assets/images/com_icono_pedir.png',
                onTap: () {
                  setState(() => _pantallaActual = _SubPantallaComunicacion.pedirAlgo);
                  _hablar('¿Qué necesitas?');
                },
              ),

              const SizedBox(height: 14),

              _buildCardMenu(
                titulo: 'Armar mi frase',
                subtitulo: 'Yo + quiero + agua',
                assetIcon: 'assets/images/com_icono_frase.png',
                onTap: () {
                  setState(() {
                    _pantallaActual = _SubPantallaComunicacion.armarFrase;
                    _reiniciarFrase();
                  });
                  _hablar('Vamos a armar tu frase. ¿Qué quieres?');
                },
              ),

              const SizedBox(height: 14),

              _buildCardMenu(
                titulo: 'Responder',
                subtitulo: 'Sí o No a una pregunta',
                widgetCustomIcon: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/resp_icono_si.png', width: 34, height: 34),
                    const SizedBox(width: 4),
                    Image.asset('assets/images/resp_icono_no.png', width: 34, height: 34),
                  ],
                ),
                onTap: () {
                  setState(() => _pantallaActual = _SubPantallaComunicacion.responder);
                  _hablar('Toca tu respuesta: Sí o No');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardMenu({
    required String titulo,
    required String subtitulo,
    String? assetIcon,
    Widget? widgetCustomIcon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 138,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorTealPrimario, width: 2.0),
        ),
        child: Row(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFE3EEF2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: widgetCustomIcon ??
                    Image.asset(
                      assetIcon!,
                      width: 58,
                      height: 58,
                      fit: BoxFit.contain,
                    ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: colorTextoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitulo,
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
          ],
        ),
      ),
    );
  }

  // Responder (US605)
  Widget _buildResponderScreen() {
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
                    'Responder',
                    style: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: colorTextoPrincipal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Toca tu respuesta',
                  style: TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorTextoPrincipal,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Expanded(
                child: InkWell(
                  onTap: () {
                    _hablar('¡Sí!');
                    _favoritosService.registrarUso('com_resp_si');
                    RegistroUsoService().registrar(RegistroUsoService.respuesta, 'si', etiqueta: 'Sí');
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7DBC5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/resp_icono_si.png',
                          width: 86,
                          height: 86,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Sí',
                          style: TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: colorTextoPrincipal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: InkWell(
                  onTap: () {
                    _hablar('¡No!');
                    _favoritosService.registrarUso('com_resp_no');
                    RegistroUsoService().registrar(RegistroUsoService.respuesta, 'no', etiqueta: 'No');
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8C9C0),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/resp_icono_no.png',
                          width: 86,
                          height: 86,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No',
                          style: TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: colorTextoPrincipal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // Pedir algo
  Widget _buildPedirAlgoScreen() {
    final pedidos = [
      ElementoPedido(
        id: 'comer',
        titulo: 'Comer',
        subtitulo: '“Quiero comer”',
        fraseVoz: 'Quiero comer',
        assetIcon: 'assets/images/pedir_comer.png',
      ),
      ElementoPedido(
        id: 'tomar',
        titulo: 'Tomar',
        subtitulo: '“Quiero tomar”',
        fraseVoz: 'Quiero tomar agua o leche',
        assetIcon: 'assets/images/pedir_tomar.png',
      ),
      ElementoPedido(
        id: 'bano',
        titulo: 'Baño',
        subtitulo: '“Quiero ir al baño”',
        fraseVoz: 'Quiero ir al baño por favor',
        assetIcon: 'assets/images/pedir_bano.png',
      ),
      ElementoPedido(
        id: 'ayuda',
        titulo: 'Ayuda',
        subtitulo: '“Necesito ayuda”',
        fraseVoz: 'Necesito ayuda por favor',
        assetIcon: 'assets/images/pedir_ayuda.png',
      ),
      ElementoPedido(
        id: 'jugar',
        titulo: 'Jugar',
        subtitulo: '“Quiero jugar”',
        fraseVoz: 'Quiero jugar un momento',
        assetIcon: 'assets/images/pedir_jugar.png',
      ),
      ElementoPedido(
        id: 'duele',
        titulo: 'Me duele',
        subtitulo: '“Me duele algo”',
        fraseVoz: 'Me duele algo, ayúdame',
        assetIcon: 'assets/images/pedir_duele.png',
      ),
    ];

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
                    'Pedir algo',
                    style: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: colorTextoPrincipal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Qué necesitas?',
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
                  itemCount: pedidos.length,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.96,
                  ),
                  itemBuilder: (context, index) {
                    final item = pedidos[index];

                    return InkWell(
                      onTap: () {
                        _hablar(item.fraseVoz);
                        _favoritosService.registrarUso('com_${item.id}');
                        if (item.id == 'comer') {
                          setState(() => _pantallaActual = _SubPantallaComunicacion.subPedidoComer);
                        } else if (item.id == 'tomar') {
                          setState(() => _pantallaActual = _SubPantallaComunicacion.subPedidoTomar);
                        } else if (item.id == 'jugar') {
                          setState(() => _pantallaActual = _SubPantallaComunicacion.subPedidoJugar);
                        } else {
                          // Necesidad directa (baño, ayuda, me duele): es una petición completa
                          RegistroUsoService().registrar(RegistroUsoService.peticion, 'com_${item.id}', etiqueta: item.fraseVoz);
                        }
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colorTealPrimario, width: 2.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              item.assetIcon,
                              width: 58,
                              height: 58,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.titulo,
                              style: const TextStyle(
                                fontFamily: 'Atkinson Hyperlegible Next',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colorTextoPrincipal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitulo,
                              style: const TextStyle(
                                fontFamily: 'Atkinson Hyperlegible Next',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: colorTextoSecundario,
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

  /// Pedido directo (Figma «Comunicación · Comer / Tomar / Jugar»): al tocar, se escucha la frase.
  Widget _buildSubOpcionesPedido({
    required String titulo,
    required String pregunta,
    required List<PedidoDirecto> opciones,
  }) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEncabezado(titulo),
              const SizedBox(height: 18),
              Text(
                pregunta,
                style: const TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  itemCount: opciones.length,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 12,
                    childAspectRatio: 150 / 220,
                  ),
                  itemBuilder: (context, index) {
                    final op = opciones[index];
                    return Semantics(
                      button: true,
                      label: op.frase,
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: () {
                          _hablar(op.frase);
                          RegistroUsoService().registrar(RegistroUsoService.peticion, op.frase, etiqueta: op.frase);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorTealPrimario, width: 2.0),
                          ),
                          child: Column(
                            children: [
                              Expanded(child: Image.asset(op.asset, fit: BoxFit.contain)),
                              const SizedBox(height: 10),
                              Text(
                                op.nombre,
                                style: const TextStyle(
                                  fontFamily: 'Atkinson Hyperlegible Next',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: colorTextoPrincipal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '“${op.frase}”',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Atkinson Hyperlegible Next',
                                  fontSize: 12,
                                  color: colorTextoSecundario,
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

  Widget _buildEncabezado(String titulo) {
    return Row(
      children: [
        Semantics(
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
        ),
        const SizedBox(width: 14),
        Text(
          titulo,
          style: const TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: colorTextoPrincipal,
          ),
        ),
      ],
    );
  }

  // Armar mi frase (US603, US604, US606; Figma «Mi frase · 1» a «· 13»)
  // Paso 1: tocar un verbo avanza solo. Pasos 2 y 3: se marca una tarjeta y «Continuar» avanza;
  // «Borrar» quita la última ficha de la franja. Baño y Ayuda terminan la frase en el paso 2.

  void _reiniciarFrase() {
    _pasoFrase = 1;
    _verbo = verbosFrase.first;
    _categoria = null;
    _objeto = null;
  }

  void _retrocederPasoFrase() {
    if (_pasoFrase == 4) {
      _pasoFrase = (_categoria != null && categoriaTienePaso3(_categoria!.id)) ? 3 : 2;
    } else if (_pasoFrase == 3) {
      _objeto = null;
      _pasoFrase = 2;
    } else if (_pasoFrase == 2) {
      _categoria = null;
      _pasoFrase = 1;
    }
  }

  void _borrarFicha() {
    setState(() {
      if (_pasoFrase == 3 && _objeto != null) {
        _objeto = null;
      } else if (_pasoFrase == 3) {
        _categoria = null;
        _pasoFrase = 2;
      } else if (_pasoFrase == 2 && _categoria != null) {
        _categoria = null;
      } else {
        _reiniciarFrase();
      }
    });
  }

  void _continuarFrase() {
    if (_pasoFrase == 2 && _categoria != null) {
      if (categoriaTienePaso3(_categoria!.id)) {
        setState(() => _pasoFrase = 3);
        _hablar(preguntaPaso3(_verbo.clave, _categoria!.id));
      } else {
        _terminarFrase();
      }
    } else if (_pasoFrase == 3 && _objeto != null) {
      _terminarFrase();
    }
  }

  String get _fraseActual => armarFrase(verbo: _verbo, categoria: _categoria!, objeto: _objeto);

  void _terminarFrase() {
    setState(() => _pasoFrase = 4);
    final frase = _fraseActual;
    _hablar(frase);
    RegistroUsoService().registrar(RegistroUsoService.peticion, 'frase', etiqueta: frase);
  }

  Widget _buildArmarFraseScreen() {
    final duele = _categoria?.id == 'duele';
    // Ficha 1: sujeto («A mí» con Me gusta o Me duele); ficha 2: verbo; ficha 3: lo elegido
    final ficha1 = _Ficha(duele ? 'A mí' : _verbo.sujeto, 'assets/images/frase_yo.png');
    final ficha2 = _pasoFrase >= 2
        ? (duele ? _Ficha('Me duele', _categoria!.asset) : _Ficha(_verbo.texto, _verbo.asset))
        : null;
    _Ficha? ficha3;
    if (_objeto != null) {
      ficha3 = _Ficha(_objeto!.nombre, _objeto!.asset);
    } else if (_categoria != null && !duele) {
      ficha3 = _Ficha(_categoria!.nombre, _categoria!.asset);
    }

    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEncabezado('Mi frase'),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorBorde, width: 1.5),
                ),
                child: Row(
                  children: [
                    _buildFichaTira(ficha1),
                    const SizedBox(width: 8),
                    _buildFichaTira(ficha2),
                    const SizedBox(width: 8),
                    _buildFichaTira(ficha3),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_pasoFrase == 1) _buildPaso1Verbo(),
              if (_pasoFrase == 2) _buildPasoOpciones(),
              if (_pasoFrase == 3) _buildPasoOpciones(),
              if (_pasoFrase == 4) _buildPaso4FraseLista(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFichaTira(_Ficha? ficha) {
    final lleno = ficha != null;
    return Expanded(
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          color: lleno ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: lleno ? colorTealPrimario : const Color(0xFFB9B2A3),
            width: 2.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (ficha != null)
              Image.asset(ficha.asset, width: 40, height: 40, fit: BoxFit.contain)
            else
              const Icon(Icons.more_horiz_rounded, size: 28, color: Color(0xFF8A8478)),
            const SizedBox(height: 4),
            Text(
              ficha != null ? ficha.texto : '…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: lleno ? colorTextoPrincipal : const Color(0xFF8A8478),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTituloPaso(String pregunta, int paso) {
    return Row(
      children: [
        Expanded(
          child: Text(
            pregunta,
            style: const TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorTextoPrincipal,
            ),
          ),
        ),
        Text(
          'Paso $paso de 3',
          style: const TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colorTealPrimario,
          ),
        ),
      ],
    );
  }

  // Paso 1: elegir el verbo
  Widget _buildPaso1Verbo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTituloPaso('¿Qué quieres?', 1),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: 151 / 150,
              children: [
                for (final v in verbosFrase)
                  _buildCardOpcionFrase(
                    titulo: v.texto,
                    subtitulo: v.clave == 'megusta' ? '“A mí me gusta”' : null,
                    assetIcon: v.asset,
                    onTap: () {
                      setState(() {
                        _verbo = v;
                        _categoria = null;
                        _objeto = null;
                        _pasoFrase = 2;
                      });
                      _hablar('${v.sujeto} ${v.texto.toLowerCase()}');
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pasos 2 y 3: marcar una tarjeta y continuar
  Widget _buildPasoOpciones() {
    final paso2 = _pasoFrase == 2;
    final opciones = paso2 ? categoriasFrase : (objetosFrase[_categoria!.id] ?? const <OpcionComunicacion>[]);
    final marcada = paso2 ? _categoria : _objeto;
    final pregunta = paso2 ? preguntaPaso2(_verbo.clave) : preguntaPaso3(_verbo.clave, _categoria!.id);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTituloPaso(pregunta, _pasoFrase),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              itemCount: opciones.length,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: 151 / 104,
              ),
              itemBuilder: (context, i) {
                final o = opciones[i];
                return _buildCardOpcionFrase(
                  titulo: o.nombre,
                  assetIcon: o.asset,
                  marcada: marcada?.id == o.id,
                  onTap: () {
                    setState(() {
                      if (paso2) {
                        _categoria = o;
                        _objeto = null;
                      } else {
                        _objeto = o;
                      }
                    });
                    _hablar(o.nombre);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 112,
                height: 52,
                child: OutlinedButton(
                  onPressed: _borrarFicha,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: colorBorde, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Borrar',
                    style: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorTextoPrincipal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: marcada == null ? null : _continuarFrase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorTealPrimario,
                      disabledBackgroundColor: const Color(0xFFC9D5DA),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Paso 4: frase lista (US603)
  Widget _buildPaso4FraseLista() {
    final frase = _fraseActual;
    return Expanded(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDDE9EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.volume_up_outlined, size: 18, color: colorTealPrimario),
                SizedBox(width: 8),
                Text(
                  'Escuchando…',
                  style: TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorTealPrimario,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            frase,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: colorTextoPrincipal,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _hablar(_fraseActual),
              icon: const Icon(Icons.volume_up_outlined, color: colorTealPrimario, size: 22),
              label: const Text(
                'Escuchar otra vez',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorTealPrimario,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: colorBorde, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                setState(_reiniciarFrase);
                _hablar('Vamos a armar otra frase');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTealPrimario,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Armar otra frase',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCardOpcionFrase({
    required String titulo,
    String? subtitulo,
    required String assetIcon,
    bool marcada = false,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: marcada,
      label: titulo,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: marcada ? const Color(0xFFDDE9EC) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorTealPrimario, width: marcada ? 3.0 : 2.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(assetIcon, width: 48, height: 48, fit: BoxFit.contain),
              const SizedBox(height: 8),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
              if (subtitulo != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 11.5,
                    color: colorTextoSecundario,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Ficha {
  final String texto;
  final String asset;

  const _Ficha(this.texto, this.asset);
}
