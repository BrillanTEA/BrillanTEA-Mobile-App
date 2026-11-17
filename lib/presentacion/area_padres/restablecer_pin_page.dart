import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dominio/auth_service.dart';
import '../comun/pin_input_cuadros.dart';
import '../inicio/inicio_page.dart';

/// Recuperación del PIN (US1003; Figma «Verifica que eres tú», «Respuestas incorrectas», «Último
/// intento», «Opción bloqueada», «Identidad verificada», «Restablecer PIN» y «PIN Restablecido»):
/// nombre, apellido y ciudad del perfil del adulto, con bloqueo de 5 minutos tras 3 intentos fallidos.
class RestablecerPinPage extends StatefulWidget {
  final VoidCallback onPinRestablecido;

  const RestablecerPinPage({super.key, required this.onPinRestablecido});

  @override
  State<RestablecerPinPage> createState() => _RestablecerPinPageState();
}

class _RestablecerPinPageState extends State<RestablecerPinPage>
    with WidgetsBindingObserver {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorInput = Color(0xFFF6F6F4);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorPista = Color(0xFF9A948A);

  static const Color colorErrorFondo = Color(0xFFFDF7F7);
  static const Color colorErrorBorde = Color(0xFFC97469);
  static const Color colorErrorTexto = Color(0xFFB3453A);
  static const Color colorErrorCirculo = Color(0xFFF5DCDA);

  static const Color colorBloqueoContadorFondo = Color(0xFFF5DDD8);
  static const Color colorBloqueoContadorBorde = Color(0xFFC97C6E);
  static const Color colorBloqueoTexto = Color(0xFFA85A47);

  final AuthService _auth = AuthService();

  // Paso 1: preguntas | 4: identidad verificada | 2: nuevo PIN | 3: PIN guardado
  int _paso = 1;

  final TextEditingController _r1Ctrl = TextEditingController();
  final TextEditingController _r2Ctrl = TextEditingController();
  final TextEditingController _r3Ctrl = TextEditingController();

  final TextEditingController _nuevoPinCtrl = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  String? _errorNombre;
  String? _errorApellido;
  String? _errorCiudad;
  String? _errorGeneral;

  /// Tras un intento fallido se muestran las respuestas en rojo y «Reintentar» (Figma «Respuestas
  /// incorrectas»); al reintentar, si queda un solo intento el título pasa a «Último intento».
  bool _respuestasIncorrectas = false;
  int _intentosRestantes = 3;

  static final List<TextInputFormatter> _formatosTexto = [
    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s\-]")),
    LengthLimitingTextInputFormatter(40),
  ];

  bool _estaBloqueado = false;
  int _segundosRestantesBloqueo = 0;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verificarEstadoBloqueo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockoutTimer?.cancel();
    _r1Ctrl.dispose();
    _r2Ctrl.dispose();
    _r3Ctrl.dispose();
    _nuevoPinCtrl.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verificarEstadoBloqueo();
    }
  }

  Future<void> _verificarEstadoBloqueo() async {
    final bloqueado = await _auth.isLocked();
    final segs = await _auth.getRemainingLockSeconds();
    if (!mounted) return;

    if (bloqueado && segs > 0) {
      setState(() {
        _estaBloqueado = true;
        _segundosRestantesBloqueo = segs;
      });
      _iniciarTimerRegresivo();
    } else {
      _lockoutTimer?.cancel();
      setState(() {
        _estaBloqueado = false;
        _errorGeneral = null;
        _segundosRestantesBloqueo = 0;
      });
    }
  }

  void _iniciarTimerRegresivo() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final segs = await _auth.getRemainingLockSeconds();
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (segs > 0) {
        setState(() {
          _estaBloqueado = true;
          _segundosRestantesBloqueo = segs;
        });
      } else {
        timer.cancel();
        await _auth.isLocked();
        if (!mounted) return;
        setState(() {
          _estaBloqueado = false;
          _errorGeneral = null;
          _segundosRestantesBloqueo = 0;
        });
      }
    });
  }

  void _irAHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const InicioPage()),
      (route) => false,
    );
  }

  Future<void> _verificarRespuestas() async {
    setState(() {
      _errorGeneral = null;
      _errorNombre = null;
      _errorApellido = null;
      _errorCiudad = null;
    });

    final r1 = _r1Ctrl.text.trim();
    final r2 = _r2Ctrl.text.trim();
    final r3 = _r3Ctrl.text.trim();

    bool hayCamposVacios = false;

    if (r1.isEmpty) {
      _errorNombre = 'Falta escribir tu nombre.';
      hayCamposVacios = true;
    }
    if (r2.isEmpty) {
      _errorApellido = 'Falta escribir tu apellido.';
      hayCamposVacios = true;
    }
    if (r3.isEmpty) {
      _errorCiudad = 'Falta escribir tu ciudad.';
      hayCamposVacios = true;
    }
    if (hayCamposVacios) {
      setState(() {});
      return;
    }

    // Cada pulsación de Verificar cuenta como un intento (incluso con las mismas respuestas)
    final res = await _auth.verificarRespuestasRecuperacionDetallado(
      nombre: r1,
      apellido: r2,
      ciudad: r3,
    );
    if (!mounted) return;

    if (res.bloqueado) {
      setState(() {
        _estaBloqueado = true;
        _segundosRestantesBloqueo = res.segundosBloqueo;
      });
      _iniciarTimerRegresivo();
      return;
    }

    if (res.exito) {
      setState(() {
        _paso = 4;
        _respuestasIncorrectas = false;
        _errorGeneral = null;
        _errorNombre = null;
        _errorApellido = null;
        _errorCiudad = null;
      });
    } else {
      // No se indica cuál respuesta falló: se marcan las tres, como en el Figma
      setState(() {
        _respuestasIncorrectas = true;
        _intentosRestantes = res.intentosRestantes;
      });
    }
  }

  void _reintentar() {
    setState(() {
      _respuestasIncorrectas = false;
      _r1Ctrl.clear();
      _r2Ctrl.clear();
      _r3Ctrl.clear();
    });
  }

  Future<void> _guardarNuevoPin() async {
    final pin = _nuevoPinCtrl.text;
    if (pin.length != 4) {
      setState(() => _errorGeneral = 'El PIN debe tener 4 dígitos.');
      return;
    }

    await _auth.actualizarPin(pin);
    widget.onPinRestablecido();
    setState(() => _paso = 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: _estaBloqueado
            ? _buildPantallaOpcionBloqueada()
            : _paso == 1
                ? _buildPasoPreguntas()
                : _paso == 4
                    ? _buildPasoIdentidadVerificada()
                    : _paso == 2
                        ? _buildPasoNuevoPin()
                        : _buildPasoPinGuardado(),
      ),
    );
  }

  Widget _buildPantallaOpcionBloqueada() {
    final minutos = (_segundosRestantesBloqueo ~/ 60).toString().padLeft(2, '0');
    final segundos = (_segundosRestantesBloqueo % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(button: true, label: 'Volver', child: InkWell(
              onTap: _irAHome,
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
          ),

          const SizedBox(height: 24),

          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: colorErrorCirculo,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.lock_clock_rounded,
                size: 38,
                color: colorBloqueoTexto,
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Opción bloqueada',
            style: TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorTextoPrincipal,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 8),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Superaste el límite de 3 intentos. Por seguridad, podrás intentarlo de nuevo en 5 minutos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: 15.5,
                height: 1.45,
                color: colorTextoSecundario,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          const SizedBox(height: 28),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: colorBloqueoContadorFondo,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorBloqueoContadorBorde, width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  '$minutos:$segundos',
                  style: const TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: colorBloqueoTexto,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'minutos restantes',
                  style: TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorBloqueoTexto,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF3E4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7D3A8), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.shield_outlined, color: Color(0xFF6B5A2E), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Por protección de los datos y configuración del menor, el acceso está temporalmente inhabilitado.',
                    style: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B5A2E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _irAHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTealPrimario,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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

  Widget _buildPasoPreguntas() {
    final error = _respuestasIncorrectas;
    final ultimo = !error && _intentosRestantes == 1;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(button: true, label: 'Volver', child: InkWell(
              onTap: () => Navigator.pop(context),
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
          ),

          const SizedBox(height: 18),

          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: error ? colorErrorCirculo : const Color(0xFFDDE9EC),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                error ? Icons.gpp_bad_outlined : Icons.gpp_maybe_outlined,
                size: 36,
                color: error ? colorErrorTexto : colorTealPrimario,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            error
                ? 'Respuestas incorrectas'
                : ultimo
                    ? 'Último intento'
                    : 'Verifica que eres tú',
            style: const TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorTextoPrincipal,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              error
                  ? 'Alguna respuesta no coincide. Revisa e inténtalo de nuevo.'
                  : ultimo
                      ? 'Responde estas 3 preguntas de tu perfil para cambiar el PIN.'
                      : 'Responde estas 3 preguntas para poder cambiar el PIN.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: 15.5,
                height: 1.45,
                color: colorTextoSecundario,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          const SizedBox(height: 18),

          if (!error) Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFDDE9EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded, color: Color(0xFF2F5563), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Son siempre las mismas y salen de los datos de tu perfil.',
                    style: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2F5563),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildCampoPregunta(
            label: '1. ¿Cuál es tu nombre?',
            ctrl: _r1Ctrl,
            hint: 'Escribe tu respuesta',
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            formatters: _formatosTexto,
            errorTexto: _errorNombre,
            incorrecta: error,
            onChanged: (_) {
              if (_errorNombre != null) setState(() => _errorNombre = null);
            },
          ),
          const SizedBox(height: 14),
          _buildCampoPregunta(
            label: '2. ¿Cuál es tu apellido?',
            ctrl: _r2Ctrl,
            hint: 'Escribe tu respuesta',
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            formatters: _formatosTexto,
            errorTexto: _errorApellido,
            incorrecta: error,
            onChanged: (_) {
              if (_errorApellido != null) setState(() => _errorApellido = null);
            },
          ),
          const SizedBox(height: 14),
          _buildCampoPregunta(
            label: '3. ¿En qué ciudad vives?',
            ctrl: _r3Ctrl,
            hint: 'Escribe tu respuesta',
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            formatters: _formatosTexto,
            errorTexto: _errorCiudad,
            incorrecta: error,
            onChanged: (_) {
              if (_errorCiudad != null) setState(() => _errorCiudad = null);
            },
          ),

          if (error) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.close_rounded, color: colorErrorTexto, size: 22),
                const SizedBox(width: 6),
                Text(
                  _intentosRestantes == 1 ? 'Te queda 1 intento' : 'Te quedan $_intentosRestantes intentos',
                  style: const TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: colorErrorTexto,
                  ),
                ),
              ],
            ),
          ],

          if (_errorGeneral != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF0EF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorErrorBorde.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: colorErrorTexto, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorGeneral!,
                      style: const TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        color: colorErrorTexto,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: error ? _reintentar : _verificarRespuestas,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTealPrimario,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                error ? 'Reintentar' : 'Verificar',
                style: const TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          if (error)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF3E4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7D3A8), width: 1.5),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF6B5A2E), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Después de 3 intentos fallidos, se bloquea esta opción por 5 minutos.',
                      style: TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF6B5A2E),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: colorTealPrimario,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasoIdentidadVerificada() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(button: true, label: 'Volver', child: InkWell(
              onTap: () => Navigator.pop(context),
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
          ),
          const SizedBox(height: 24),
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(color: Color(0xFFCFE3D2), shape: BoxShape.circle),
            child: const Center(
              child: Icon(Icons.verified_user_outlined, size: 36, color: Color(0xFF3F5E48)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '¡Identidad verificada!',
            style: TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorTextoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Tus respuestas son correctas. Ya puedes crear un nuevo PIN.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: 15.5,
                height: 1.45,
                color: colorTextoSecundario,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => setState(() => _paso = 2),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTealPrimario,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Crear nuevo PIN',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasoNuevoPin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(button: true, label: 'Volver', child: InkWell(
              onTap: () => setState(() => _paso = 4),
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
          ),
          const SizedBox(height: 24),
          Container(
            width: 76,
            height: 74,
            decoration: const BoxDecoration(
              color: Color(0xFFDDE9EC),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.lock_open_rounded, size: 38, color: colorTealPrimario),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Crea un nuevo PIN',
            style: TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorTextoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Elige un PIN de 4 dígitos que solo tú conozcas. Lo necesitarás cada vez que quieras entrar a esta sección.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: 15.5,
                height: 1.45,
                color: colorTextoSecundario,
              ),
            ),
          ),
          const SizedBox(height: 32),
          PinInputCuadros(
            controller: _nuevoPinCtrl,
            focusNode: _pinFocusNode,
            esError: _errorGeneral != null,
            onChanged: (_) {
              if (_errorGeneral != null) {
                setState(() => _errorGeneral = null);
              } else {
                setState(() {});
              }
            },
            onCompleted: (_) {
              setState(() {});
            },
          ),
          if (_errorGeneral != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorGeneral!,
              style: const TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                color: colorErrorTexto,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _guardarNuevoPin,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTealPrimario,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Guardar PIN',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasoPinGuardado() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 76,
            height: 75,
            decoration: const BoxDecoration(
              color: Color(0xFFDCEEDD),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.check_rounded, size: 38, color: Color(0xFF5E8C68)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '¡PIN guardado!',
            style: TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorTextoPrincipal,
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Tu nuevo PIN se guardó correctamente. Ingrésalo para acceder a la sección de padres.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: 15.5,
                height: 1.45,
                color: colorTextoSecundario,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTealPrimario,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Ingresar PIN',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCampoPregunta({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    List<TextInputFormatter>? formatters,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? errorTexto,
    bool incorrecta = false,
    ValueChanged<String>? onChanged,
  }) {
    final tieneError = errorTexto != null || incorrecta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colorTextoPrincipal,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: incorrecta ? colorErrorCirculo : (tieneError ? colorErrorFondo : colorInput),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tieneError ? colorErrorBorde : colorBorde,
              width: tieneError ? 1.8 : 1.5,
            ),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: formatters,
            onChanged: onChanged,
            style: TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: incorrecta ? colorErrorTexto : colorTextoPrincipal,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: colorPista, fontSize: 15),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (errorTexto != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, size: 14, color: colorErrorTexto),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorTexto,
                  style: const TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colorErrorTexto,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
