import 'package:flutter/material.dart';

import '../../dominio/auth_service.dart';
import '../area_padres/tutoriales_page.dart';
import '../comun/pin_input_cuadros.dart';

/// Creación del PIN en el primer uso y confirmación «PIN guardado».
class NuevoPinRegistroPage extends StatefulWidget {
  final PerfilAdulto perfilAdulto;
  final PerfilNino perfilNino;

  const NuevoPinRegistroPage({
    super.key,
    required this.perfilAdulto,
    required this.perfilNino,
  });

  @override
  State<NuevoPinRegistroPage> createState() => _NuevoPinRegistroPageState();
}

class _NuevoPinRegistroPageState extends State<NuevoPinRegistroPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorExitoFondo = Color(0xFFDCEEDD);
  static const Color colorExitoTexto = Color(0xFF5E8C68);

  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  bool _pinGuardadoConExito = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  String get _pinCompleto => _pinController.text;

  Future<void> _guardarPin() async {
    final pin = _pinCompleto;
    if (pin.length != 4) {
      setState(() => _error = 'Por favor ingresa los 4 dígitos.');
      return;
    }

    final auth = AuthService();
    await auth.registrarPrimerUso(
      adulto: widget.perfilAdulto,
      pin: pin,
      nino: widget.perfilNino,
    );

    setState(() => _pinGuardadoConExito = true);
  }

  void _irAInicio() {
    Navigator.of(context).pushAndRemoveUntil(
      // Al terminar el registro se invita a ver los tutoriales.
      MaterialPageRoute(builder: (_) => const InvitacionPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _pinGuardadoConExito ? _buildPantallaPinGuardado() : _buildPantallaNuevoPin(),
        ),
      ),
    );
  }

  Widget _buildPantallaNuevoPin() {
    final tecladoVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            key: const ValueKey('NuevoPIN'),
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: IntrinsicHeight(
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

                    SizedBox(height: tecladoVisible ? 10 : 24),

                    Container(
                      width: tecladoVisible ? 58 : 76,
                      height: tecladoVisible ? 58 : 74,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDDE9EC),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.lock_open_rounded,
                          size: tecladoVisible ? 30 : 38,
                          color: colorTealPrimario,
                        ),
                      ),
                    ),

                    SizedBox(height: tecladoVisible ? 10 : 20),

                    const Text(
                      'Crea un nuevo PIN',
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
                        'Elige un PIN de 4 dígitos que solo tú conozcas. Lo necesitarás cada vez que quieras entrar al área de padres.',
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

                    SizedBox(height: tecladoVisible ? 16 : 32),

                    PinInputCuadros(
                      controller: _pinController,
                      focusNode: _pinFocusNode,
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
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    const Spacer(),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _guardarPin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorTealPrimario,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPantallaPinGuardado() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          key: const ValueKey('PINGuardado'),
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Container(
                    width: 76,
                    height: 75,
                    decoration: const BoxDecoration(
                      color: colorExitoFondo,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: 38,
                        color: colorExitoTexto,
                      ),
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
                      letterSpacing: -0.3,
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
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _irAInicio,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorTealPrimario,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
