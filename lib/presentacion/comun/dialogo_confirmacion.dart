import 'package:flutter/material.dart';

/// Diálogo de confirmación del Figma («¿Guardar los cambios?», «¿Salir sin guardar?»):
/// ícono en un círculo, título, texto y dos botones. Devuelve true con el botón principal,
/// false con el secundario y null si se cierra tocando fuera.
enum TipoDialogo { guardar, aviso }

const String _fuente = 'Atkinson Hyperlegible Next';
const Color _texto = Color(0xFF3A3A3A);
const Color _textoSecundario = Color(0xFF6B6B66);
const Color _teal = Color(0xFF3D6D7E);
const Color _borde = Color(0xFFDDD6C9);
const Color _rojo = Color(0xFFB4533F);

Future<bool?> mostrarDialogoConfirmacion(
  BuildContext context, {
  required TipoDialogo tipo,
  required String titulo,
  required String texto,
  required String primario,
  required String secundario,
  bool secundarioRojo = false,
}) {
  final guardar = tipo == TipoDialogo.guardar;
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ExcludeSemantics(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: guardar ? const Color(0xFFDDE9EC) : const Color(0xFFF8EBC4),
                shape: BoxShape.circle,
              ),
              child: Icon(guardar ? Icons.check_rounded : Icons.priority_high_rounded,
                  color: guardar ? _teal : const Color(0xFF9A7414), size: 30),
            ),
          ),
          const SizedBox(height: 14),
          Text(titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: _fuente, fontSize: 21, fontWeight: FontWeight.w700, color: _texto)),
          const SizedBox(height: 8),
          Text(texto,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: _fuente, fontSize: 14, height: 1.4, color: _textoSecundario)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(primario, style: const TextStyle(fontFamily: _fuente, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: secundarioRojo ? _rojo : _teal,
                side: BorderSide(color: secundarioRojo ? _rojo : _borde, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(secundario, style: const TextStyle(fontFamily: _fuente, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    ),
  );
}
