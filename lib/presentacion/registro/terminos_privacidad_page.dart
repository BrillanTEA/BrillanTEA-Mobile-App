import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../dominio/auth_service.dart';
import '../../dominio/documentos_legales.dart';
import '../comun/hoja_documento_legal.dart';
import 'perfil_responsable_page.dart';

/// Términos y privacidad del primer uso (US901; Figma «Términos y privacidad» y «· Aceptado»).
/// El adulto puede leer los dos documentos en una hoja inferior y solo continúa al marcar la casilla.
class TerminosPrivacidadPage extends StatefulWidget {
  const TerminosPrivacidadPage({super.key});

  @override
  State<TerminosPrivacidadPage> createState() => _TerminosPrivacidadPageState();
}

class _TerminosPrivacidadPageState extends State<TerminosPrivacidadPage> {
  static const String _fuente = 'Atkinson Hyperlegible Next';
  static const Color _texto = Color(0xFF3A3A3A);
  static const Color _textoSecundario = Color(0xFF6B6B66);
  static const Color _teal = Color(0xFF3D6D7E);
  static const Color _tealDeshabilitado = Color(0xFFC9D5DA);
  static const Color _tealClaro = Color(0xFFE8F1F5);
  static const Color _fondoTarjeta = Color(0xFFF6F6F4);
  static const Color _borde = Color(0xFFDDD6C9);

  bool _acepto = false;
  bool _guardando = false;
  late final TapGestureRecognizer _tapTerminos;
  late final TapGestureRecognizer _tapPolitica;

  @override
  void initState() {
    super.initState();
    _tapTerminos = TapGestureRecognizer()..onTap = () => _abrir(terminosYCondiciones);
    _tapPolitica = TapGestureRecognizer()..onTap = () => _abrir(politicaDePrivacidad);
  }

  @override
  void dispose() {
    _tapTerminos.dispose();
    _tapPolitica.dispose();
    super.dispose();
  }

  void _abrir(DocumentoLegal documento) => mostrarHojaDocumentoLegal(context, documento);

  Future<void> _continuar() async {
    if (!_acepto || _guardando) return;
    setState(() => _guardando = true);
    await AuthService().setAcuerdoPrivacidadAceptado(true);
    if (!mounted) return;
    setState(() => _guardando = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PerfilResponsablePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      _encabezado(),
                      const SizedBox(height: 20),
                      const Text(
                        'Antes de empezar, lee cómo cuidamos tu información y la del niño o niña.',
                        style: TextStyle(fontFamily: _fuente, fontSize: 18, color: _textoSecundario),
                      ),
                      const SizedBox(height: 24),
                      _enlace(
                        titulo: 'Términos y condiciones',
                        subtitulo: 'Normas para usar la aplicación.',
                        onTap: () => _abrir(terminosYCondiciones),
                      ),
                      const SizedBox(height: 12),
                      _enlace(
                        titulo: 'Política de privacidad',
                        subtitulo: 'Cómo se cuidan y protegen los datos.',
                        onTap: () => _abrir(politicaDePrivacidad),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _consentimiento(),
              const SizedBox(height: 26),
              _botonContinuar(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _encabezado() {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Volver',
          excludeSemantics: true,
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _borde, width: 1.5),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: _texto, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Términos y privacidad',
            style: TextStyle(
              fontFamily: _fuente,
              fontSize: 24,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: _texto,
            ),
          ),
        ),
      ],
    );
  }

  Widget _enlace({required String titulo, required String subtitulo, required VoidCallback onTap}) {
    return Semantics(
      button: true,
      label: '$titulo. $subtitulo',
      excludeSemantics: true,
      child: Material(
        color: _fondoTarjeta,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _borde, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 84),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontFamily: _fuente,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _texto,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitulo,
                          style: const TextStyle(fontFamily: _fuente, fontSize: 14, color: _textoSecundario),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _texto, size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _consentimiento() {
    const enlace = TextStyle(
      fontWeight: FontWeight.w700,
      color: _teal,
      decoration: TextDecoration.underline,
      decorationColor: _teal,
    );
    return Semantics(
      checked: _acepto,
      label: 'Estoy de acuerdo con los Términos y condiciones y la Política de privacidad',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _acepto = !_acepto),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: _acepto ? _tealClaro : _fondoTarjeta,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _acepto ? _teal : _borde, width: 1.5),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _acepto ? _teal : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _teal, width: 2),
                ),
                child: _acepto ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontFamily: _fuente, fontSize: 16, color: _texto),
                    children: [
                      const TextSpan(text: 'Estoy de acuerdo con los '),
                      TextSpan(text: 'Términos y condiciones', style: enlace, recognizer: _tapTerminos),
                      const TextSpan(text: ' y la '),
                      TextSpan(text: 'Política de privacidad', style: enlace, recognizer: _tapPolitica),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonContinuar() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _acepto && !_guardando ? _continuar : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          disabledBackgroundColor: _tealDeshabilitado,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'Continuar',
          style: TextStyle(fontFamily: _fuente, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
