import 'package:flutter/material.dart';

import '../../dominio/auth_service.dart';
import '../comun/pin_input_cuadros.dart';

/// Cambio del PIN de 4 dígitos del responsable.
class CambiarPinPage extends StatefulWidget {
  const CambiarPinPage({super.key});

  @override
  State<CambiarPinPage> createState() => _CambiarPinPageState();
}

class _CambiarPinPageState extends State<CambiarPinPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorTealClaro = Color(0xFFDDE9EC);
  static const Color colorBotonDeshabilitado = Color(0xFFC9D5DA);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _error;
  bool _guardando = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _pinCompleto => _controller.text;

  Future<void> _guardarPin() async {
    final pin = _pinCompleto;
    if (pin.length != 4) {
      setState(() => _error = 'Por favor ingresa los 4 dígitos del nuevo PIN.');
      return;
    }

    setState(() => _guardando = true);
    await AuthService().actualizarPin(pin);
    setState(() => _guardando = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '¡PIN actualizado correctamente!',
          style: TextStyle(fontFamily: 'Atkinson Hyperlegible Next'),
        ),
        backgroundColor: colorTealPrimario,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool pinCompleto = _pinCompleto.length == 4;

    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Semantics(button: true, label: 'Volver', child: InkWell(
                onTap: () => Navigator.maybePop(context),
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
              )),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: const BoxDecoration(
                            color: colorTealClaro,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.lock_outline_rounded,
                              color: colorTealPrimario,
                              size: 42,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Crea un nuevo PIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: colorTextoPrincipal,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Elige un PIN de 4 dígitos que solo tú conozcas. Lo necesitarás cada vez que quieras entrar a esta sección.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 15,
                            height: 1.45,
                            color: colorTextoSecundario,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      PinInputCuadros(
                        controller: _controller,
                        focusNode: _focusNode,
                        boxWidth: 60,
                        boxHeight: 66,
                        boxMargin: 6,
                        borderRadius: 14,
                        fontSize: 26,
                        esError: _error != null,
                        onChanged: (_) {
                          if (_error != null) {
                            setState(() => _error = null);
                          } else {
                            setState(() {});
                          }
                        },
                        onCompleted: (_) {
                          setState(() {});
                        },
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 13.5,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: pinCompleto && !_guardando ? _guardarPin : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorTealPrimario,
                    disabledBackgroundColor: colorBotonDeshabilitado,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Guardar PIN',
                          style: TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
