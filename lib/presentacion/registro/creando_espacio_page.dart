import 'dart:async';

import 'package:flutter/material.dart';

import '../../dominio/auth_service.dart';
import 'nuevo_pin_registro_page.dart';

/// Pantalla de transición «Creando espacio» (1,8 s) antes de crear el PIN.
class CreandoEspacioPage extends StatefulWidget {
  final PerfilAdulto perfilAdulto;
  final PerfilNino perfilNino;

  const CreandoEspacioPage({
    super.key,
    required this.perfilAdulto,
    required this.perfilNino,
  });

  @override
  State<CreandoEspacioPage> createState() => _CreandoEspacioPageState();
}

class _CreandoEspacioPageState extends State<CreandoEspacioPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => NuevoPinRegistroPage(
              perfilAdulto: widget.perfilAdulto,
              perfilNino: widget.perfilNino,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colorTextoPrincipal = Color(0xFF3A3A3A);
    const colorTextoSecundario = Color(0xFF6B6B66);
    const colorTealPrimario = Color(0xFF3D6D7E);

    final nombreNino = widget.perfilNino.nombre.isNotEmpty ? widget.perfilNino.nombre : 'tu pequeño';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(colorTealPrimario),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Estamos creando el espacio de $nombreNino ...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: colorTextoPrincipal,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Esto solo tomará un momento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 16,
                    height: 1.5,
                    color: colorTextoSecundario,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
