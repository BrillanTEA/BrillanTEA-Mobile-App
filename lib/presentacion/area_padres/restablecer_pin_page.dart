import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dominio/auth_service.dart';
import '../comun/formatters.dart';
import '../comun/pin_input_cuadros.dart';
import '../inicio/inicio_page.dart';

/// Recuperación del PIN: tres preguntas del perfil del adulto (bloqueo de 5 minutos tras 3 intentos
/// fallidos), nuevo PIN y confirmación.
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

  // Paso 1: Preguntas (Último intento) | Paso 2: Nuevo PIN | Paso 3: PIN Guardado
  int _paso = 1;

  final TextEditingController _r1Ctrl = TextEditingController();
  final TextEditingController _r2Ctrl = TextEditingController();
  final TextEditingController _r3Ctrl = TextEditingController();

  final TextEditingController _nuevoPinCtrl = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  String? _errorAnio;
  String? _errorMaterno;
  String? _errorCiudad;
  String? _errorGeneral;

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
      _errorAnio = null;
      _errorMaterno = null;
      _errorCiudad = null;
    });

    final r1 = _r1Ctrl.text.trim();
    final r2 = _r2Ctrl.text.trim();
    final r3 = _r3Ctrl.text.trim();

    bool hayCamposVacios = false;

    if (r1.isEmpty) {
      _errorAnio = 'Ingresa el año en que naciste.';
      hayCamposVacios = true;
    } else if (r1.length < 4) {
      _errorAnio = 'Ingresa un año de 4 dígitos (Ej. 1988).';
      hayCamposVacios = true;
    }

    if (r2.isEmpty) {
      _errorMaterno = 'Ingresa tu apellido materno.';
      hayCamposVacios = true;
    }

    if (r3.isEmpty) {
      _errorCiudad = 'Ingresa tu ciudad de nacimiento.';
      hayCamposVacios = true;
    }

    if (hayCamposVacios) {
      setState(() {
        _errorGeneral = 'Por favor completa todos los campos requeridos.';
      });
      return;
    }

    // Cada pulsación de Verificar evalúa contra los datos y cuenta el intento (incluso con datos repetidos)
    final res = await _auth.verificarRespuestasRecuperacionDetallado(
      anioNacimiento: r1,
      apellidoMaterno: r2,
      ciudadNacimiento: r3,
    );

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
        _paso = 2;
        _errorGeneral = null;
        _errorAnio = null;
        _errorMaterno = null;
        _errorCiudad = null;
      });
    } else {
      setState(() {
        if (!res.anioValido) {
          _errorAnio = 'El año de nacimiento no coincide.';
        }
        if (!res.apellidoValido) {
          _errorMaterno = 'El apellido materno no coincide.';
        }
        if (!res.ciudadValida) {
          _errorCiudad = 'La ciudad de nacimiento no coincide.';
        }

        final restanteTxt = res.intentosRestantes == 1
            ? 'Te queda 1 intento antes del bloqueo.'
            : 'Te quedan ${res.intentosRestantes} intentos antes del bloqueo.';

        _errorGeneral = 'Intento ${res.intentosFallidos} de 3 fallido. $restanteTxt';
      });
    }
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
                ? _buildPasoUltimoIntento()
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

  Widget _buildPasoUltimoIntento() {
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
            decoration: const BoxDecoration(
              color: Color(0xFFDDE9EC),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.security_rounded,
                size: 38,
                color: colorTealPrimario,
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Último intento',
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
              'Responde estas 3 preguntas de tu perfil para cambiar el PIN.',
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

          const SizedBox(height: 18),

          Container(
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
                    'Son siempre las mismas y nunca se olvidan.',
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

          // Pregunta 1: año de nacimiento (solo dígitos)
          _buildCampoPregunta(
            label: '1. ¿En qué año naciste?',
            ctrl: _r1Ctrl,
            hint: 'Ej. 1988',
            keyboardType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            errorTexto: _errorAnio,
            onChanged: (_) {
              if (_errorAnio != null || _errorGeneral != null) {
                setState(() {
                  _errorAnio = null;
                  _errorGeneral = null;
                });
              }
            },
          ),
          const SizedBox(height: 14),

          _buildCampoPregunta(
            label: '2. ¿Cuál es tu apellido materno?',
            ctrl: _r2Ctrl,
            hint: 'Ej. Ruiz',
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            formatters: [
              SinTildesFormatter(),
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZñÑ\s\-]")),
              LengthLimitingTextInputFormatter(40),
            ],
            errorTexto: _errorMaterno,
            onChanged: (_) {
              if (_errorMaterno != null || _errorGeneral != null) {
                setState(() {
                  _errorMaterno = null;
                  _errorGeneral = null;
                });
              }
            },
          ),
          const SizedBox(height: 14),

          _buildCampoPregunta(
            label: '3. ¿En qué ciudad naciste?',
            ctrl: _r3Ctrl,
            hint: 'Ej. Lima',
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            formatters: [
              SinTildesFormatter(),
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZñÑ\s\-]")),
              LengthLimitingTextInputFormatter(40),
            ],
            errorTexto: _errorCiudad,
            onChanged: (_) {
              if (_errorCiudad != null || _errorGeneral != null) {
                setState(() {
                  _errorCiudad = null;
                  _errorGeneral = null;
                });
              }
            },
          ),

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
              onPressed: _verificarRespuestas,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTealPrimario,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Verificar',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

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

  Widget _buildPasoNuevoPin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(button: true, label: 'Volver', child: InkWell(
              onTap: () => setState(() => _paso = 1),
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
                'Continuar',
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
    ValueChanged<String>? onChanged,
  }) {
    final tieneError = errorTexto != null;

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
            color: tieneError ? colorErrorFondo : colorInput,
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
            style: const TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorTextoPrincipal,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: colorPista, fontSize: 15),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (tieneError) ...[
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
