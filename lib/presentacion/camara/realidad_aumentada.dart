import 'dart:math';

import 'package:flutter/material.dart';

import '../../infraestructura/detector_worker.dart';

/// Ancho y alto de la tarjeta de realidad aumentada (pictograma + nombre), en píxeles lógicos.
const double kAnchoTarjetaRA = 172;
const double kAltoTarjetaRA = 64;

/// Fracción de la vista a partir de la cual un objeto se considera "muy grande".
const double kFraccionObjetoGrande = 0.40;

/// Convierte una detección (normalizada 0–1 sobre el frame girado) a píxeles de la vista,
/// teniendo en cuenta el recorte de BoxFit.cover de la vista previa.
Rect cajaEnVista(Detection d, Size vista, Size? frame) {
  if (frame == null || frame.width <= 0 || frame.height <= 0) {
    return Rect.fromLTRB(d.left * vista.width, d.top * vista.height,
        d.right * vista.width, d.bottom * vista.height);
  }
  final escala = max(vista.width / frame.width, vista.height / frame.height);
  final dx = (vista.width - frame.width * escala) / 2;
  final dy = (vista.height - frame.height * escala) / 2;
  return Rect.fromLTRB(
    dx + d.left * frame.width * escala,
    dy + d.top * frame.height * escala,
    dx + d.right * frame.width * escala,
    dy + d.bottom * frame.height * escala,
  );
}

/// Lugar en la pantalla de la tarjeta de un objeto reconocido.
class UbicacionTarjetaRA {
  const UbicacionTarjetaRA(this.caja, this.tarjeta, this.grande);

  /// Caja del objeto en píxeles de la vista (recortada al borde de la pantalla).
  final Rect caja;

  /// Rectángulo donde se dibuja la tarjeta.
  final Rect tarjeta;

  /// El objeto ocupa más del 40 % de la vista: no se dibuja el marco y la tarjeta va al centro.
  final bool grande;
}

/// Ubica la tarjeta de cada objeto (realidad aumentada en el espacio de pantalla):
/// 1) encima del objeto; 2) debajo, si no cabe arriba; 3) dentro y arriba, si tampoco cabe
/// abajo; 4) sobre el centro, si el objeto es muy grande. Si una tarjeta tapa a otra ya
/// ubicada, se corre debajo (o encima) de ella. Ninguna tarjeta sale de la pantalla.
/// Devuelve null para las cajas que quedan fuera de la vista.
List<UbicacionTarjetaRA?> ubicarTarjetasRA(
  List<Rect> cajas,
  Size vista, {
  double ancho = kAnchoTarjetaRA,
  double alto = kAltoTarjetaRA,
}) {
  const margen = 8.0;
  final maxX = max(margen, vista.width - ancho - margen);
  final maxY = max(margen, vista.height - alto - margen);
  final ocupadas = <Rect>[];
  final resultado = <UbicacionTarjetaRA?>[];
  for (final original in cajas) {
    final caja = original.intersect(Offset.zero & vista);
    if (caja.width <= 0 || caja.height <= 0) {
      resultado.add(null);
      continue;
    }
    final grande =
        caja.width * caja.height > kFraccionObjetoGrande * vista.width * vista.height;
    final x = (caja.center.dx - ancho / 2).clamp(margen, maxX).toDouble();
    var y = caja.top - alto - 10; // encima del objeto
    if (grande) {
      y = (caja.center.dy - alto / 2).clamp(margen, maxY).toDouble();
    } else {
      if (y < margen) y = caja.bottom + 10; // si no cabe arriba, debajo
      if (y > maxY) {
        y = (caja.top + 10).clamp(margen, maxY).toDouble(); // dentro, arriba
      }
    }
    var r = Rect.fromLTWH(x, y, ancho, alto);
    for (final o in ocupadas) {
      if (r.overlaps(o.inflate(4))) {
        y = (o.bottom + 8 <= maxY) ? o.bottom + 8 : max(margen, o.top - alto - 8);
        r = Rect.fromLTWH(x, y, ancho, alto);
      }
    }
    ocupadas.add(r);
    resultado.add(UbicacionTarjetaRA(caja, r, grande));
  }
  return resultado;
}
