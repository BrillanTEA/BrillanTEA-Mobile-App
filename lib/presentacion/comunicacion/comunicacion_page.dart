import 'package:flutter/material.dart';

import '../../dominio/accesibilidad_service.dart';
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
  int _pasoFrase = 1; // 1: Verbo, 2: Categoría, 3: Objeto, 4: Frase Lista
  String _verboKey = 'quiero'; // quiero, noquiero, necesito, megusta
  String _verboTexto = 'Quiero';
  String _sujetoTexto = 'Yo';
  String _categoriaFrase = 'Tomar';
  String _objetoTexto = 'Agua';
  String? _objetoAsset;

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
        setState(() => _pasoFrase--);
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
          opciones: [
            {'nombre': 'Manzana', 'frase': 'Quiero manzana', 'asset': 'assets/pictogramas/manzana_2462.png'},
            {'nombre': 'Plátano', 'frase': 'Quiero plátano', 'asset': 'assets/pictogramas/platano_2530.png'},
            {'nombre': 'Naranja', 'frase': 'Quiero naranja', 'asset': 'assets/pictogramas/naranja_2888.png'},
            {'nombre': 'Sándwich', 'frase': 'Quiero sándwich', 'asset': 'assets/pictogramas/sandwich_3383.png'},
            {'nombre': 'Torta', 'frase': 'Quiero torta', 'asset': 'assets/pictogramas/torta_2579.png'},
            {'nombre': 'Zanahoria', 'frase': 'Quiero zanahoria', 'asset': 'assets/pictogramas/zanahoria_2619.png'},
          ],
        );
      case _SubPantallaComunicacion.subPedidoTomar:
        return _buildSubOpcionesPedido(
          titulo: 'Tomar',
          opciones: [
            {'nombre': 'Agua', 'frase': 'Quiero agua', 'asset': 'assets/pictogramas/vaso_2610.png'},
            {'nombre': 'Leche', 'frase': 'Quiero leche', 'asset': 'assets/pictogramas/vaso_2610.png'},
            {'nombre': 'Jugo', 'frase': 'Quiero jugo', 'asset': 'assets/pictogramas/botella_2288.png'},
            {'nombre': 'Botella', 'frase': 'Quiero mi botella', 'asset': 'assets/pictogramas/botella_2288.png'},
          ],
        );
      case _SubPantallaComunicacion.subPedidoJugar:
        return _buildSubOpcionesPedido(
          titulo: 'Jugar',
          opciones: [
            {'nombre': 'Pelota', 'frase': 'Quiero jugar con la pelota', 'asset': 'assets/pictogramas/pelota_3241.png'},
            {'nombre': 'Bloques', 'frase': 'Quiero jugar con bloques', 'asset': 'assets/pictogramas/bloques_de_construccion_4935.png'},
            {'nombre': 'Peluche', 'frase': 'Quiero mi peluche', 'asset': 'assets/pictogramas/peluche_4945.png'},
            {'nombre': 'Juguetes', 'frase': 'Quiero guardar mis juguetes', 'asset': 'assets/pictogramas/caja_organizadora_7054.png'},
          ],
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
                    _pasoFrase = 1;
                    _sujetoTexto = 'Yo';
                    _verboTexto = 'Quiero';
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

  Widget _buildSubOpcionesPedido({
    required String titulo,
    required List<Map<String, String>> opciones,
  }) {
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
                  Text(
                    'Pedir · $titulo',
                    style: const TextStyle(
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
                'Elige lo que deseas:',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorTextoPrincipal,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  itemCount: opciones.length,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.94,
                  ),
                  itemBuilder: (context, index) {
                    final op = opciones[index];
                    return InkWell(
                      onTap: () {
                        _hablar(op['frase']!);
                        RegistroUsoService().registrar(RegistroUsoService.peticion, op['frase']!, etiqueta: op['frase']!);
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
                            Expanded(
                              child: Center(
                                child: Image.asset(
                                  op['asset']!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              op['nombre']!,
                              style: const TextStyle(
                                fontFamily: 'Atkinson Hyperlegible Next',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colorTextoPrincipal,
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

  // Armar mi frase (US603, US604, US606)
  Widget _buildArmarFraseScreen() {
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
                    'Mi frase',
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

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorBorde, width: 1.5),
                ),
                child: Row(
                  children: [
                    // Ficha 1: Sujeto ("Yo" o "A mí" según US604)
                    _buildFichaTira(
                      texto: _sujetoTexto,
                      assetIcon: 'assets/images/frase_yo.png',
                      lleno: true,
                    ),
                    const SizedBox(width: 8),

                    _buildFichaTira(
                      texto: _pasoFrase >= 2 ? _verboTexto : 'Dice…',
                      assetIcon: _pasoFrase >= 2 ? 'assets/images/frase_$_verboKey.png' : null,
                      lleno: _pasoFrase >= 2,
                    ),
                    const SizedBox(width: 8),

                    _buildFichaTira(
                      texto: _pasoFrase >= 4 ? _objetoTexto : '…',
                      assetIcon: _pasoFrase >= 4 ? _objetoAsset : null,
                      lleno: _pasoFrase >= 4,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_pasoFrase == 1) _buildPaso1Verbo(),
              if (_pasoFrase == 2) _buildPaso2Categoria(),
              if (_pasoFrase == 3) _buildPaso3Objeto(),
              if (_pasoFrase == 4) _buildPaso4FraseLista(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFichaTira({
    required String texto,
    String? assetIcon,
    required bool lleno,
  }) {
    return Expanded(
      child: Container(
        height: 80,
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
            if (assetIcon != null)
              Image.asset(assetIcon, width: 36, height: 36, fit: BoxFit.contain)
            else
              const Icon(Icons.more_horiz_rounded, size: 28, color: Color(0xFF8A8478)),
            const SizedBox(height: 4),
            Text(
              texto,
              style: TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: lleno ? colorTextoPrincipal : const Color(0xFF8A8478),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Paso 1: elegir verbo
  Widget _buildPaso1Verbo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '¿Qué quieres?',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
              Text(
                'Paso 1 de 3',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colorTealPrimario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.98,
              children: [
                _buildCardOpcionFrase(
                  titulo: 'Quiero',
                  assetIcon: 'assets/images/frase_quiero.png',
                  onTap: () => _seleccionarVerbo('quiero', 'Quiero', 'Yo'),
                ),
                _buildCardOpcionFrase(
                  titulo: 'No quiero',
                  assetIcon: 'assets/images/frase_noquiero.png',
                  onTap: () => _seleccionarVerbo('noquiero', 'No quiero', 'Yo'),
                ),
                _buildCardOpcionFrase(
                  titulo: 'Necesito',
                  assetIcon: 'assets/images/frase_necesito.png',
                  onTap: () => _seleccionarVerbo('necesito', 'Necesito', 'Yo'),
                ),
                // US604: Cambia sujeto a "A mí" cuando elige "Me gusta"
                _buildCardOpcionFrase(
                  titulo: 'Me gusta',
                  subtitulo: '“A mí me gusta”',
                  assetIcon: 'assets/images/frase_megusta.png',
                  onTap: () => _seleccionarVerbo('megusta', 'Me gusta', 'A mí'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _seleccionarVerbo(String key, String verbo, String sujeto) {
    setState(() {
      _verboKey = key;
      _verboTexto = verbo;
      _sujetoTexto = sujeto;
      _pasoFrase = 2;
    });
    _hablar('$_sujetoTexto $verbo');
  }

  // Paso 2: elegir categoría
  Widget _buildPaso2Categoria() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '¿De qué se trata?',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
              Text(
                'Paso 2 de 3',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colorTealPrimario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.98,
              children: [
                _buildCardOpcionFrase(
                  titulo: 'Tomar',
                  assetIcon: 'assets/images/pedir_tomar.png',
                  onTap: () => _seleccionarCategoria('Tomar'),
                ),
                _buildCardOpcionFrase(
                  titulo: 'Comer',
                  assetIcon: 'assets/images/pedir_comer.png',
                  onTap: () => _seleccionarCategoria('Comer'),
                ),
                _buildCardOpcionFrase(
                  titulo: 'Jugar',
                  assetIcon: 'assets/images/pedir_jugar.png',
                  onTap: () => _seleccionarCategoria('Jugar'),
                ),
                _buildCardOpcionFrase(
                  titulo: 'Ayuda',
                  assetIcon: 'assets/images/pedir_ayuda.png',
                  onTap: () => _seleccionarCategoria('Ayuda'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _seleccionarCategoria(String cat) {
    setState(() {
      _categoriaFrase = cat;
      _pasoFrase = 3;
    });
    _hablar('Elige qué quieres en $cat');
  }

  // Paso 3: elegir pictograma
  Widget _buildPaso3Objeto() {
    List<Map<String, String>> items = [];
    if (_categoriaFrase == 'Tomar') {
      items = [
        {'nombre': 'Agua', 'asset': 'assets/pictogramas/vaso_2610.png'},
        {'nombre': 'Leche', 'asset': 'assets/pictogramas/vaso_2610.png'},
        {'nombre': 'Jugo', 'asset': 'assets/pictogramas/botella_2288.png'},
      ];
    } else if (_categoriaFrase == 'Comer') {
      items = [
        {'nombre': 'Manzana', 'asset': 'assets/pictogramas/manzana_2462.png'},
        {'nombre': 'Plátano', 'asset': 'assets/pictogramas/platano_2530.png'},
        {'nombre': 'Sándwich', 'asset': 'assets/pictogramas/sandwich_3383.png'},
        {'nombre': 'Galleta', 'asset': 'assets/pictogramas/torta_2579.png'},
      ];
    } else if (_categoriaFrase == 'Jugar') {
      items = [
        {'nombre': 'Pelota', 'asset': 'assets/pictogramas/pelota_3241.png'},
        {'nombre': 'Bloques', 'asset': 'assets/pictogramas/bloques_de_construccion_4935.png'},
        {'nombre': 'Peluche', 'asset': 'assets/pictogramas/peluche_4945.png'},
      ];
    } else {
      items = [
        {'nombre': 'Un abrazo', 'asset': 'assets/images/home_emociones.png'},
        {'nombre': 'Descansar', 'asset': 'assets/pictogramas/cama_25900.png'},
        {'nombre': 'El baño', 'asset': 'assets/images/pedir_bano.png'},
      ];
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Elige el dibujo',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
              Text(
                'Paso 3 de 3',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colorTealPrimario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Expanded(
            child: GridView.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.98,
              ),
              itemBuilder: (context, index) {
                final it = items[index];
                return _buildCardOpcionFrase(
                  titulo: it['nombre']!,
                  assetIcon: it['asset']!,
                  onTap: () {
                    setState(() {
                      _objetoTexto = it['nombre']!;
                      _objetoAsset = it['asset']!;
                      _pasoFrase = 4;
                    });
                    _hablarFraseCompleta();
                    final fraseArmada = _verboKey == 'megusta'
                        ? 'A mí me gusta $_objetoTexto'
                        : '$_sujetoTexto $_verboTexto $_objetoTexto';
                    RegistroUsoService().registrar(RegistroUsoService.peticion, 'frase', etiqueta: fraseArmada);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _hablarFraseCompleta() {
    String frase = '$_sujetoTexto $_verboTexto $_objetoTexto';
    if (_verboKey == 'megusta') {
      frase = 'A mí me gusta $_objetoTexto';
    }
    _hablar(frase);
  }

  // Paso 4: frase lista (US603)
  Widget _buildPaso4FraseLista() {
    final fraseCompleta = _verboKey == 'megusta'
        ? 'A mí me gusta $_objetoTexto'
        : '$_sujetoTexto $_verboTexto $_objetoTexto';

    return Expanded(
      child: Column(
        children: [
          const Spacer(),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3EEF2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.volume_up_rounded, size: 20, color: colorTealPrimario),
                      SizedBox(width: 8),
                      Text(
                        '¡Tu frase está lista!',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorTealPrimario,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  fraseCompleta,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: colorTextoPrincipal,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _hablarFraseCompleta,
              icon: const Icon(Icons.refresh_rounded, color: colorTealPrimario, size: 22),
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
                side: const BorderSide(color: colorTealPrimario, width: 2.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _pasoFrase = 1;
                  _sujetoTexto = 'Yo';
                  _verboTexto = 'Quiero';
                });
                _hablar('Vamos a armar otra frase');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTealPrimario,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorTealPrimario, width: 2.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetIcon, width: 50, height: 50, fit: BoxFit.contain),
            const SizedBox(height: 10),
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
                  fontWeight: FontWeight.w400,
                  color: colorTextoSecundario,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
