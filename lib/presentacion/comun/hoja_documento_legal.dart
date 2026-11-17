import 'package:flutter/material.dart';

import '../../dominio/documentos_legales.dart';

/// Hoja inferior con el texto completo de un documento legal (Figma: «Términos y privacidad ·
/// Hoja Términos» y «· Hoja Política»). El texto se desplaza dentro de la hoja; «Entendido» o la X
/// la cierran. Se usa en el registro (US901) y en Ayuda y soporte → Acerca de.
Future<void> mostrarHojaDocumentoLegal(BuildContext context, DocumentoLegal documento) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x73282828),
    builder: (_) => HojaDocumentoLegal(documento: documento),
  );
}

class HojaDocumentoLegal extends StatelessWidget {
  final DocumentoLegal documento;

  const HojaDocumentoLegal({super.key, required this.documento});

  static const String _fuente = 'Atkinson Hyperlegible Next';
  static const Color _texto = Color(0xFF3A3A3A);
  static const Color _textoSecundario = Color(0xFF6B6B66);
  static const Color _teal = Color(0xFF3D6D7E);
  static const Color _tealOscuro = Color(0xFF2F5A69);
  static const Color _divisorSuave = Color(0xFFEEE8DE);
  static const Color _borde = Color(0xFFDDD6C9);
  static const Color _fondoTarjeta = Color(0xFFF6F6F4);
  static const Color _bordeTarjeta = Color(0xFF8EB8C7);

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.of(context).size.height * (704 / 760);
    return Container(
      height: alto,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(color: _borde, borderRadius: BorderRadius.circular(3)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 9, 24, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        documento.titulo,
                        style: const TextStyle(
                          fontFamily: _fuente,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: _texto,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        documento.version,
                        style: const TextStyle(fontFamily: _fuente, fontSize: 13, color: _textoSecundario),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Cerrar',
                  excludeSemantics: true,
                  child: Material(
                    color: _fondoTarjeta,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.close_rounded, size: 20, color: _texto),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1.5, color: _divisorSuave),
          Expanded(
            child: Scrollbar(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                itemCount: documento.bloques.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _bloque(documento.bloques[i]),
              ),
            ),
          ),
          Container(height: 1.5, color: _divisorSuave),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(fontFamily: _fuente, fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloque(BloqueLegal b) {
    switch (b.tipo) {
      case TipoBloqueLegal.titulo:
        return Text(
          b.texto,
          style: const TextStyle(
            fontFamily: _fuente,
            fontSize: 19,
            height: 25 / 19,
            fontWeight: FontWeight.w700,
            color: _tealOscuro,
          ),
        );
      case TipoBloqueLegal.parrafo:
        return Text.rich(_tramos(b.tramos, _teal, 16, 1.6));
      case TipoBloqueLegal.vineta:
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '•',
                style: TextStyle(
                  fontFamily: _fuente,
                  fontSize: 16,
                  height: 1.6,
                  fontWeight: FontWeight.w700,
                  color: _teal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text.rich(_tramos(b.tramos, _teal, 16, 1.6))),
            ],
          ),
        );
      case TipoBloqueLegal.tarjeta:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
          decoration: const BoxDecoration(
            color: _fondoTarjeta,
            border: Border(left: BorderSide(color: _bordeTarjeta, width: 4)),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.texto,
                style: const TextStyle(
                  fontFamily: _fuente,
                  fontSize: 15.5,
                  height: 21 / 15.5,
                  fontWeight: FontWeight.w700,
                  color: _texto,
                ),
              ),
              for (final linea in b.lineas) ...[
                const SizedBox(height: 3),
                Text.rich(_tramos(linea, _textoSecundario, 14.5, 20 / 14.5)),
              ],
            ],
          ),
        );
      case TipoBloqueLegal.espacio:
        return const SizedBox(height: 8);
      case TipoBloqueLegal.divisor:
        return Container(height: 1.5, color: _borde);
      case TipoBloqueLegal.pie:
        return Text(
          b.texto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: _fuente,
            fontSize: 13,
            height: 18 / 13,
            color: _textoSecundario,
          ),
        );
    }
  }

  TextSpan _tramos(List<TramoLegal> tramos, Color colorAcento, double tamano, double alto) {
    return TextSpan(
      style: TextStyle(fontFamily: _fuente, fontSize: tamano, height: alto, color: _texto),
      children: [
        for (final t in tramos)
          TextSpan(
            text: t.texto,
            style: TextStyle(
              fontWeight: t.negrita ? FontWeight.w700 : FontWeight.w400,
              color: t.acento ? colorAcento : null,
            ),
          ),
      ],
    );
  }
}
