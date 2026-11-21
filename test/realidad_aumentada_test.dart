import 'package:brillantea/infraestructura/detector_worker.dart';
import 'package:brillantea/presentacion/camara/realidad_aumentada.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pruebas de la capa de realidad aumentada de la Cámara (RF-01, RF-02, US304).
void main() {
  const vista = Size(400, 800);

  group('cajaEnVista: de la detección del modelo a píxeles de la pantalla', () {
    test('sin tamaño de frame, escala la caja normalizada a la vista', () {
      final d = Detection(0, 0.9, 0.25, 0.5, 0.75, 0.75);
      expect(cajaEnVista(d, vista, null), const Rect.fromLTRB(100, 400, 300, 600));
    });

    test('descuenta el recorte de BoxFit.cover de la vista previa', () {
      // Frame vertical de 720 × 1280 mostrado en 400 × 800: escala 0,625 y 25 px recortados a cada lado.
      final d = Detection(0, 0.9, 0.5, 0.5, 0.625, 0.625);
      expect(cajaEnVista(d, vista, const Size(720, 1280)),
          const Rect.fromLTRB(200, 400, 256.25, 500));
    });
  });

  group('ubicarTarjetasRA: dónde aparece la tarjeta de cada objeto', () {
    test('pone la tarjeta encima del objeto, centrada', () {
      final u = ubicarTarjetasRA([const Rect.fromLTRB(150, 300, 250, 400)], vista).single!;
      expect(u.grande, isFalse);
      expect(u.tarjeta, const Rect.fromLTWH(114, 226, kAnchoTarjetaRA, kAltoTarjetaRA));
    });

    test('si no cabe arriba, la pone debajo del objeto', () {
      final u = ubicarTarjetasRA([const Rect.fromLTRB(150, 20, 250, 120)], vista).single!;
      expect(u.tarjeta.top, 130);
    });

    test('si tampoco cabe abajo, la pone dentro del objeto, arriba', () {
      final u = ubicarTarjetasRA([const Rect.fromLTRB(100, 30, 180, 790)], vista).single!;
      expect(u.grande, isFalse);
      expect(u.tarjeta.top, 40);
      expect(u.tarjeta.left, 54);
    });

    test('con un objeto muy grande (más del 40 % de la vista) la pone al centro y sin marco', () {
      final u = ubicarTarjetasRA([const Rect.fromLTRB(0, 0, 400, 600)], vista).single!;
      expect(u.grande, isTrue);
      expect(u.tarjeta.center, const Offset(200, 300));
    });

    test('dos tarjetas nunca se tapan', () {
      final us = ubicarTarjetasRA([
        const Rect.fromLTRB(100, 300, 200, 400),
        const Rect.fromLTRB(110, 310, 210, 410),
      ], vista);
      expect(us[0]!.tarjeta.top, 226);
      expect(us[1]!.tarjeta.top, 298);
      expect(us[0]!.tarjeta.overlaps(us[1]!.tarjeta), isFalse);
    });

    test('la tarjeta no sale de la pantalla y un objeto fuera de la vista no tiene tarjeta', () {
      final us = ubicarTarjetasRA([
        const Rect.fromLTRB(350, 400, 450, 500),
        const Rect.fromLTRB(500, 0, 600, 100),
      ], vista);
      expect(us[0]!.caja.right, 400);
      expect(us[0]!.tarjeta.left, 220);
      expect(us[0]!.tarjeta.right, lessThanOrEqualTo(vista.width - 8));
      expect(us[1], isNull);
    });
  });
}
