import 'package:flutter/material.dart';

import '../../dominio/auth_service.dart';
import '../comun/pin_input_cuadros.dart';
import '../registro/bienvenida_page.dart';

/// Borrar los datos (US1007): opción definitiva del área de padres. Pide otra vez el PIN y, si es
/// correcto, elimina perfiles, PIN, configuración, favoritos, progreso, seguimiento, notas y copias
/// temporales del reporte; luego la aplicación vuelve al primer uso.
/// Con [retirarConsentimiento] es el retiro del consentimiento (Términos 11.2): hace lo mismo, con
/// textos que explican que para volver a usar la app hay que aceptar otra vez.
Future<void> confirmarBorrarDatos(BuildContext context, {bool retirarConsentimiento = false}) async {
  final nav = Navigator.of(context);
  final borrado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DialogoBorrarDatos(retirarConsentimiento: retirarConsentimiento),
  );
  if (borrado == true) {
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BienvenidaPage(saltarSplash: true)),
      (route) => false,
    );
  }
}

class _DialogoBorrarDatos extends StatefulWidget {
  final bool retirarConsentimiento;
  const _DialogoBorrarDatos({required this.retirarConsentimiento});

  @override
  State<_DialogoBorrarDatos> createState() => _DialogoBorrarDatosState();
}

class _DialogoBorrarDatosState extends State<_DialogoBorrarDatos> {
  static const String _fuente = 'Atkinson Hyperlegible Next';
  static const Color _colorTextoSecundario = Color(0xFF6B6B66);

  final TextEditingController _pin = TextEditingController();
  final AuthService _auth = AuthService();
  String? _error;
  bool _borrando = false;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _borrar() async {
    if (_pin.text.length != 4 || _borrando) return;
    setState(() {
      _borrando = true;
      _error = null;
    });

    if (await _auth.isLocked()) {
      final segundos = await _auth.getRemainingLockSeconds();
      if (!mounted) return;
      _pin.clear();
      setState(() {
        _borrando = false;
        _error = 'PIN bloqueado. Intenta de nuevo en ${(segundos / 60).ceil()} min.';
      });
      return;
    }

    final correcto = await _auth.verificarPin(_pin.text);
    if (!mounted) return;
    if (!correcto) {
      final bloqueado = await _auth.isLocked();
      if (!mounted) return;
      _pin.clear();
      setState(() {
        _borrando = false;
        _error = bloqueado ? 'Demasiados intentos. Espera 5 minutos.' : 'PIN incorrecto.';
      });
      return;
    }

    await _auth.reiniciarTodo();
    if (mounted) Navigator.of(context).pop(true);
  }

  /// Mismo estilo que los diálogos del Figma (Privacidad y datos · Retirar consentimiento / Borrar los datos).
  @override
  Widget build(BuildContext context) {
    const rojo = Color(0xFFB4533F);
    const borde = Color(0xFFDDD6C9);
    const teal = Color(0xFF3D6D7E);
    final retirar = widget.retirarConsentimiento;
    final listo = _pin.text.length == 4 && !_borrando;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(color: Color(0xFFFDE8E8), shape: BoxShape.circle),
                child: Icon(retirar ? Icons.do_not_disturb_on_outlined : Icons.delete_outline_rounded,
                    color: rojo, size: 28),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              retirar ? '¿Retirar tu consentimiento?' : '¿Borrar los datos?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: _fuente, fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xFF3A3A3A)),
            ),
            const SizedBox(height: 10),
            Text(
              retirar
                  ? 'La app dejará de usar los datos del niño o niña. Se borrará todo lo guardado en este teléfono '
                      'y volverás al inicio. Para usarla otra vez tendrás que aceptar de nuevo los Términos y la Política.'
                  : 'Se eliminarán de este teléfono los perfiles, el PIN, la configuración, los favoritos, el progreso, '
                      'el seguimiento y las notas. La app volverá al primer uso. No se puede deshacer.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: _fuente, fontSize: 13.5, height: 1.4, color: _colorTextoSecundario),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ingresa tu PIN para confirmar',
              style: TextStyle(fontFamily: _fuente, fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF3A3A3A)),
            ),
            const SizedBox(height: 10),
            PinInputCuadros(
              controller: _pin,
              esError: _error != null,
              enabled: !_borrando,
              boxWidth: 48,
              boxHeight: 56,
              fontSize: 22,
              onChanged: (_) => setState(() => _error = null),
              onCompleted: (_) => setState(() {}),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, style: const TextStyle(fontFamily: _fuente, color: rojo)),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: listo ? _borrar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: rojo,
                  disabledBackgroundColor: rojo.withValues(alpha: 0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _borrando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(retirar ? 'Retirar consentimiento' : 'Borrar los datos',
                        style: const TextStyle(
                            fontFamily: _fuente, fontSize: 15.5, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _borrando ? null : () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: teal,
                  side: const BorderSide(color: borde, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancelar',
                    style: TextStyle(fontFamily: _fuente, fontSize: 15.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
