import 'dart:async';

import 'package:flutter/material.dart';

import '../../dominio/auth_service.dart';
import '../inicio/inicio_page.dart';
import 'perfil_responsable_page.dart';

/// Pantalla de carga y bienvenida («Hola»).
class BienvenidaPage extends StatefulWidget {
  final bool saltarSplash;
  const BienvenidaPage({super.key, this.saltarSplash = false});

  @override
  State<BienvenidaPage> createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends State<BienvenidaPage> {
  bool _mostrarHola = false;
  Timer? _timerSplash;

  @override
  void initState() {
    super.initState();
    _iniciarFlujo();
  }

  Future<void> _iniciarFlujo() async {
    if (widget.saltarSplash) {
      if (mounted) setState(() => _mostrarHola = true);
      return;
    }

    final configurado = await AuthService().isConfigured();

    _timerSplash = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      if (configurado) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InicioPage()),
        );
      } else {
        setState(() => _mostrarHola = true);
      }
    });
  }

  @override
  void dispose() {
    _timerSplash?.cancel();
    super.dispose();
  }

  void _irAPerfilResponsable() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PerfilResponsablePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _mostrarHola
            ? SafeArea(child: _buildBienvenidaHola())
            : _buildPantallaCarga(),
      ),
    );
  }

  Widget _buildPantallaCarga() {
    final alturaOlas = MediaQuery.of(context).size.height * 0.26;

    return GestureDetector(
      key: const ValueKey('PantallaCarga'),
      onTap: () async {
        _timerSplash?.cancel();
        final configurado = await AuthService().isConfigured();
        if (!mounted) return;
        if (configurado) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const InicioPage()),
          );
        } else {
          setState(() => _mostrarHola = true);
        }
      },
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: alturaOlas.clamp(220.0, 300.0),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _OlasDecorativasPainter(),
              ),
            ),
          ),
          Center(
            child: Transform.translate(
              offset: const Offset(0, -25),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo_brillantea.png',
                      width: 290,
                      cacheWidth: 580,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Un mundo de aprendizaje\ny comunicación para ti.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 19,
                        height: 1.4,
                        color: Color(0xFF62677F),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBienvenidaHola() {
    return Column(
      key: const ValueKey('BienvenidaHola'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola!',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF033878),
                  letterSpacing: -1.0,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Aquí puedes explorar, aprender y comunicarte de forma divertida.',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 18,
                  height: 1.35,
                  color: Color(0xFF7E88A4),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: Image.asset(
            'assets/images/ilustracion_ninos.png',
            width: double.infinity,
            fit: BoxFit.fitWidth,
            filterQuality: FilterQuality.high,
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _irAPerfilResponsable,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D6D7E),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Comenzar',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _OlasDecorativasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Ola crema (capa posterior, curva suave de izquierda a derecha)
    final paintCrema = Paint()..color = const Color(0xFFFDEFD9);
    final pathCrema = Path()
      ..moveTo(0, size.height * 0.22)
      ..cubicTo(
        size.width * 0.35, size.height * 0.22,
        size.width * 0.65, size.height * 0.68,
        size.width, size.height * 0.38,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(pathCrema, paintCrema);

    // 2. Ola azul suave (capa frontal, curva fluida que asciende a la derecha)
    final paintAzul = Paint()..color = const Color(0xFFD7EBF8);
    final pathAzul = Path()
      ..moveTo(0, size.height * 0.58)
      ..cubicTo(
        size.width * 0.30, size.height * 0.50,
        size.width * 0.55, size.height * 0.78,
        size.width, size.height * 0.35,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(pathAzul, paintAzul);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
