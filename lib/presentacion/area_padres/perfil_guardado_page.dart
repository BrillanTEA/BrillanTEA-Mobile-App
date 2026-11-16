import 'package:flutter/material.dart';

/// Confirmación tras actualizar el perfil del menor desde el Área de padres.
class PerfilGuardadoPage extends StatelessWidget {
  final String nombreNino;

  const PerfilGuardadoPage({
    super.key,
    required this.nombreNino,
  });

  @override
  Widget build(BuildContext context) {
    const colorFondo = Color(0xFFFFFFFF);
    const colorTextoPrincipal = Color(0xFF3A3A3A);
    const colorTextoSecundario = Color(0xFF6B6B66);
    const colorTealPrimario = Color(0xFF3D6D7E);
    const colorTealClaro = Color(0xFFDDE9EC);

    final displayNombre = nombreNino.trim().isNotEmpty ? nombreNino.trim() : 'Mateo';

    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: colorTealClaro,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: colorTealPrimario,
                    size: 52,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                '¡Perfil guardado!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Guardamos el perfil de $displayNombre. Ya puedes empezar a usar la app con su información personalizada.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 15.5,
                  height: 1.45,
                  color: colorTextoSecundario,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorTealPrimario,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Ir a Área de padres',
                    style: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
