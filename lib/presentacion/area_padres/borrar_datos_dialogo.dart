import 'package:flutter/material.dart';

import '../../dominio/auth_service.dart';
import '../comun/pin_input_cuadros.dart';
import '../registro/bienvenida_page.dart';

/// Borrar los datos (US1007): opción definitiva del área de padres. Pide otra vez el PIN y, si es
/// correcto, elimina perfiles, PIN, configuración, favoritos, progreso, seguimiento, notas y copias
/// temporales del reporte; luego la aplicación vuelve al primer uso.
Future<void> confirmarBorrarDatos(BuildContext context) async {
  final nav = Navigator.of(context);
  final borrado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DialogoBorrarDatos(),
  );
  if (borrado == true) {
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BienvenidaPage(saltarSplash: true)),
      (route) => false,
    );
  }
}

class _DialogoBorrarDatos extends StatefulWidget {
  const _DialogoBorrarDatos();

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

  @override
  Widget build(BuildContext context) {
    final listo = _pin.text.length == 4 && !_borrando;
    return AlertDialog(
      title: const Text(
        '¿Borrar los datos?',
        style: TextStyle(fontFamily: _fuente, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Se eliminarán de este dispositivo los perfiles, el PIN, la configuración, los favoritos, '
              'el progreso, el seguimiento y las notas. La aplicación volverá al primer uso. '
              'Esta acción no se puede deshacer.',
              style: TextStyle(fontFamily: _fuente, fontSize: 15),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ingresa tu PIN para confirmar',
              style: TextStyle(fontFamily: _fuente, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Center(
              child: PinInputCuadros(
                controller: _pin,
                esError: _error != null,
                enabled: !_borrando,
                boxWidth: 48,
                boxHeight: 56,
                fontSize: 22,
                onChanged: (_) => setState(() => _error = null),
                onCompleted: (_) => setState(() {}),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: TextStyle(fontFamily: _fuente, color: Colors.red.shade700),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _borrando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar', style: TextStyle(fontFamily: _fuente, color: _colorTextoSecundario)),
        ),
        ElevatedButton(
          onPressed: listo ? _borrar : null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
          child: _borrando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Borrar los datos', style: TextStyle(fontFamily: _fuente, color: Colors.white)),
        ),
      ],
    );
  }
}
