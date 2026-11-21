import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../dominio/favoritos_service.dart';

/// Formas del Vocabulario. En el Figma se dibujan con contorno negro sobre fondo blanco.
enum FormaVocabulario {
  circulo,
  cuadrado,
  triangulo,
  rectangulo,
  estrella,
  rombo,
  hexagono,
  trapecio,
  pentagono,
  ovalo,
  corazon,
}

class ElementoVocabulario {
  final String id;
  final String nombre;
  final String silabas;
  final String fraseVoz;
  final String? assetPath;

  /// Número («61») o letra en mayúscula y minúscula («Gg»).
  final String? simboloTexto;
  final Color? colorVisual;
  final FormaVocabulario? forma;

  const ElementoVocabulario({
    required this.id,
    required this.nombre,
    required this.silabas,
    required this.fraseVoz,
    this.assetPath,
    this.simboloTexto,
    this.colorVisual,
    this.forma,
  });

  FavoritoItem toFavoritoItem(String categoriaNombre) {
    return FavoritoItem(
      id: id,
      nombre: nombre,
      modulo: 'Vocabulario',
      colorModuloValue: 0xFFA85D77,
      assetPath: assetPath,
      simboloTexto: simboloTexto,
      silabas: silabas,
      fraseVoz: fraseVoz,
    );
  }
}

class CategoriaVocabulario {
  final String id;
  final String nombre;
  final String subtitulo;

  /// Texto del buscador de la grilla («Buscar número»).
  final String buscador;
  final String assetBadge;
  final List<ElementoVocabulario> elementos;

  const CategoriaVocabulario({
    required this.id,
    required this.nombre,
    required this.subtitulo,
    required this.buscador,
    required this.assetBadge,
    required this.elementos,
  });
}

/// Dibuja una forma con contorno negro (Figma «Vocabulario · Formas»).
class DibujoForma extends StatelessWidget {
  final FormaVocabulario forma;
  final double tamano;

  const DibujoForma({super.key, required this.forma, required this.tamano});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano,
      height: tamano,
      child: CustomPaint(painter: _PintorForma(forma)),
    );
  }
}

class _PintorForma extends CustomPainter {
  final FormaVocabulario forma;
  _PintorForma(this.forma);

  Path _poligono(Offset c, double r, int lados, {double giro = -math.pi / 2}) {
    final p = Path();
    for (var i = 0; i < lados; i++) {
      final a = giro + 2 * math.pi * i / lados;
      final punto = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? p.moveTo(punto.dx, punto.dy) : p.lineTo(punto.dx, punto.dy);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);
    final r = math.min(w, h) * 0.42;
    final lapiz = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.025)
      ..strokeJoin = StrokeJoin.round;

    late final Path p;
    switch (forma) {
      case FormaVocabulario.circulo:
        p = Path()..addOval(Rect.fromCircle(center: c, radius: r));
      case FormaVocabulario.cuadrado:
        p = Path()..addRect(Rect.fromCenter(center: c, width: r * 1.6, height: r * 1.6));
      case FormaVocabulario.triangulo:
        p = _poligono(c.translate(0, r * 0.15), r * 1.05, 3);
      case FormaVocabulario.rectangulo:
        p = Path()..addRect(Rect.fromCenter(center: c, width: r * 2, height: r * 1.2));
      case FormaVocabulario.estrella:
        p = Path();
        for (var i = 0; i < 10; i++) {
          final a = -math.pi / 2 + math.pi * i / 5;
          final radio = i.isEven ? r : r * 0.42;
          final punto = Offset(c.dx + radio * math.cos(a), c.dy + radio * math.sin(a));
          i == 0 ? p.moveTo(punto.dx, punto.dy) : p.lineTo(punto.dx, punto.dy);
        }
        p.close();
      case FormaVocabulario.rombo:
        p = Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r * 0.75, c.dy)
          ..lineTo(c.dx, c.dy + r)
          ..lineTo(c.dx - r * 0.75, c.dy)
          ..close();
      case FormaVocabulario.hexagono:
        p = _poligono(c, r, 6, giro: 0);
      case FormaVocabulario.trapecio:
        // En el Figma el «trapecio» se dibuja inclinado (como un paralelogramo)
        p = Path()
          ..moveTo(c.dx - r * 0.55, c.dy - r * 0.5)
          ..lineTo(c.dx + r, c.dy - r * 0.5)
          ..lineTo(c.dx + r * 0.55, c.dy + r * 0.5)
          ..lineTo(c.dx - r, c.dy + r * 0.5)
          ..close();
      case FormaVocabulario.pentagono:
        p = _poligono(c.translate(0, r * 0.08), r, 5);
      case FormaVocabulario.ovalo:
        p = Path()..addOval(Rect.fromCenter(center: c, width: r * 2, height: r * 1.2));
      case FormaVocabulario.corazon:
        p = Path()
          ..moveTo(c.dx, c.dy + r * 0.9)
          ..cubicTo(c.dx - r * 1.3, c.dy + r * 0.1, c.dx - r * 0.9, c.dy - r * 1.0, c.dx, c.dy - r * 0.45)
          ..cubicTo(c.dx + r * 0.9, c.dy - r * 1.0, c.dx + r * 1.3, c.dy + r * 0.1, c.dx, c.dy + r * 0.9)
          ..close();
    }
    canvas.drawPath(p, lapiz);
  }

  @override
  bool shouldRepaint(covariant _PintorForma old) => old.forma != forma;
}
