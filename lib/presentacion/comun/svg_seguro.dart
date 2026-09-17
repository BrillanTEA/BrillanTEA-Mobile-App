import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

/// Dibuja un SVG de assets; si el archivo todavía no existe (no se corrió el script de
/// descarga de Figma), muestra un ícono de respaldo en vez de romper la pantalla.
class SvgSeguro extends StatelessWidget {
  final String ruta;
  final double ancho;
  final double alto;
  final IconData respaldo;
  final Color colorRespaldo;

  const SvgSeguro(this.ruta, this.ancho, this.alto,
      {super.key, this.respaldo = Icons.image_outlined, this.colorRespaldo = const Color(0xFF3D6D7E)});

  static final Map<String, Future<bool>> _existe = {};

  Future<bool> _hay() =>
      _existe.putIfAbsent(ruta, () => rootBundle.load(ruta).then((_) => true, onError: (_) => false));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: alto,
      child: FutureBuilder<bool>(
        future: _hay(),
        builder: (context, snap) {
          if (snap.data == true) return SvgPicture.asset(ruta, width: ancho, height: alto);
          if (snap.connectionState != ConnectionState.done) return const SizedBox.shrink();
          return Icon(respaldo, size: alto * 0.85, color: colorRespaldo);
        },
      ),
    );
  }
}
