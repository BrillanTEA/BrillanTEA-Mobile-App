import 'dart:async';

import 'package:flutter/material.dart';

import '../../dominio/auth_service.dart';
import '../comun/pin_input_cuadros.dart';
import '../inicio/inicio_page.dart';
import 'area_padres_page.dart';
import 'restablecer_pin_page.dart';

/// Acceso del adulto con PIN. Tras 3 intentos fallidos se bloquea 5 minutos.
class LoginPinPage extends StatefulWidget {
  final VoidCallback? onBack;
  final Widget? destinoTrasPin;

  const LoginPinPage({super.key, this.onBack, this.destinoTrasPin});

  @override
  State<LoginPinPage> createState() => _LoginPinPageState();
}

class _LoginPinPageState extends State<LoginPinPage> with WidgetsBindingObserver {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);

  static const Color colorErrorTexto = Color(0xFFB3453A);
  static const Color colorErrorCirculo = Color(0xFFF5DCDA);

  static const Color colorBloqueoContadorFondo = Color(0xFFF5DDD8);
  static const Color colorBloqueoContadorBorde = Color(0xFFC97C6E);
  static const Color colorBloqueoTexto = Color(0xFFA85A47);
  static const Color colorAvisoFondo = Color(0xFFFBF3E4);
  static const Color colorAvisoBorde = Color(0xFFE7D3A8);
  static const Color colorAvisoTexto = Color(0xFF6B5A2E);

  final AuthService _auth = AuthService();
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  bool _esError = false;
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
    _pinController.dispose();
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
        _esError = false;
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
          _esError = false;
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

  String get _pinCompleto => _pinController.text;

  Future<void> _validarPin() async {
    final pin = _pinCompleto;
    if (pin.length != 4) return;
    if (_estaBloqueado) return;

    final valido = await _auth.verificarPin(pin);

    if (valido) {
      if (!mounted) return;
      if (widget.destinoTrasPin != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.destinoTrasPin!),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AreaPadresPage()),
        );
      }
    } else {
      final bloqueado = await _auth.isLocked();
      setState(() {
        _esError = true;
        _estaBloqueado = bloqueado;
      });
      _pinController.clear();

      if (bloqueado) {
        final segs = await _auth.getRemainingLockSeconds();
        setState(() => _segundosRestantesBloqueo = segs);
        _iniciarTimerRegresivo();
      }
    }
  }

  void _limpiarYReintentar() {
    _pinController.clear();
    setState(() => _esError = false);
    _pinFocusNode.requestFocus();
  }

  void _abrirRestablecerPin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestablecerPinPage(
          onPinRestablecido: () {
            _verificarEstadoBloqueo();
            _limpiarYReintentar();
          },
        ),
      ),
    );
    if (mounted) {
      _verificarEstadoBloqueo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: _estaBloqueado
            ? _buildPantallaOpcionBloqueada()
            : _buildPantallaPinNormalOError(),
      ),
    );
  }

  Widget _buildPantallaPinNormalOError() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(button: true, label: 'Volver', child: InkWell(
              onTap: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
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
            decoration: BoxDecoration(
              color: _esError ? colorErrorCirculo : const Color(0xFFDDE9EC),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _esError ? Icons.lock_clock_rounded : Icons.lock_rounded,
                size: 36,
                color: _esError ? colorErrorTexto : colorTealPrimario,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            _esError ? 'PIN incorrecto' : 'Área para padres',
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
              _esError
                  ? 'El PIN que ingresaste no coincide. Verifica los 4 dígitos e inténtalo de nuevo.'
                  : 'Esta sección es solo para el familiar o tutor a cargo. Ingresa tu PIN de 4 dígitos para continuar.',
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

          const SizedBox(height: 32),

          PinInputCuadros(
            controller: _pinController,
            focusNode: _pinFocusNode,
            esError: _esError,
            enabled: !_estaBloqueado,
            onChanged: (val) {
              if (_esError) {
                setState(() => _esError = false);
              }
            },
            onCompleted: (val) {
              _validarPin();
            },
          ),

          const SizedBox(height: 20),

          if (_esError) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.close_rounded, color: colorErrorTexto, size: 18),
                SizedBox(width: 8),
                Text(
                  'PIN incorrecto, intenta nuevamente',
                  style: TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorErrorTexto,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _esError ? _limpiarYReintentar : _validarPin,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTealPrimario,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _esError ? 'Reintentar' : 'Continuar',
                style: const TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          TextButton(
            onPressed: _abrirRestablecerPin,
            child: const Text(
              '¿Olvidaste tu PIN?',
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
              'Por seguridad, podrás intentarlo de nuevo en 5 minutos.',
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorAvisoFondo,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorAvisoBorde, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline_rounded, color: colorAvisoTexto, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tu PIN actual sigue funcionando. Si lo recuerdas, puedes entrar con él.',
                    style: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 13,
                      height: 1.4,
                      color: colorAvisoTexto,
                      fontWeight: FontWeight.w400,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
