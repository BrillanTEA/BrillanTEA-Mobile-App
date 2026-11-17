import 'package:flutter/material.dart';

import '../../dominio/auth_service.dart';
import '../../dominio/documentos_legales.dart';
import '../comun/hoja_documento_legal.dart';
import 'borrar_datos_dialogo.dart';

/// Privacidad y datos (Figma «Privacidad y datos»): reúne los documentos legales, la constancia de
/// aceptación (fecha, hora y versión) y las dos opciones definitivas, Retirar consentimiento y
/// Borrar los datos (US901, US1007). Ambas piden el PIN.
class PrivacidadDatosPage extends StatefulWidget {
  const PrivacidadDatosPage({super.key});

  @override
  State<PrivacidadDatosPage> createState() => _PrivacidadDatosPageState();
}

class _PrivacidadDatosPageState extends State<PrivacidadDatosPage> {
  static const String _fuente = 'Atkinson Hyperlegible Next';
  static const Color _borde = Color(0xFFDDD6C9);
  static const Color _texto = Color(0xFF3A3A3A);
  static const Color _textoSecundario = Color(0xFF6B6B66);
  static const Color _teal = Color(0xFF3D6D7E);
  static const Color _tealClaro = Color(0xFFDDE9EC);
  static const Color _rojo = Color(0xFFB4533F);
  static const Color _rojoClaro = Color(0xFFFDE8E8);

  static const List<String> _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  RegistroAceptacion? _registro;

  @override
  void initState() {
    super.initState();
    AuthService().getRegistroAceptacion().then((r) {
      if (mounted) setState(() => _registro = r);
    });
  }

  String get _textoFecha {
    final f = _registro?.fecha;
    if (f == null) return 'Sin registro de aceptación';
    final h = f.hour.toString().padLeft(2, '0');
    final m = f.minute.toString().padLeft(2, '0');
    return 'Aceptado el ${f.day} ${_meses[f.month - 1]} ${f.year}, $h:$m';
  }

  String get _textoVersion {
    final v = _registro?.version;
    return v == null ? 'Términos y Política · versión no registrada' : 'Términos y Política · Versión $v';
  }

  Widget _tituloSeccion(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: const TextStyle(
                fontFamily: _fuente, fontSize: 12.5, fontWeight: FontWeight.w700, color: _textoSecundario, letterSpacing: 0.5)),
      );

  Widget _tarjeta(List<Widget> filas) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borde, width: 1.5),
        ),
        child: Column(children: [
          for (var i = 0; i < filas.length; i++) ...[
            if (i > 0) const Divider(height: 1.5, thickness: 1.5, color: _borde),
            filas[i],
          ],
        ]),
      );

  Widget _filaDocumento(String titulo, DocumentoLegal documento) => ListTile(
        title: Text(titulo,
            style: const TextStyle(fontFamily: _fuente, fontSize: 13.5, fontWeight: FontWeight.w600, color: _texto)),
        trailing: const Icon(Icons.chevron_right_rounded, color: _textoSecundario, size: 26),
        onTap: () => mostrarHojaDocumentoLegal(context, documento),
      );

  Widget _icono(IconData icono, Color color, Color fondo) => Container(
        width: 43,
        height: 40,
        decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
        child: Icon(icono, color: color, size: 20),
      );

  Widget _textos(String titulo, String subtitulo) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontFamily: _fuente, fontSize: 15, fontWeight: FontWeight.w700, color: _texto)),
          const SizedBox(height: 2),
          Text(subtitulo, style: const TextStyle(fontFamily: _fuente, fontSize: 12, color: _textoSecundario)),
        ],
      );

  Widget _filaAccion({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required VoidCallback onTap,
  }) =>
      Semantics(
        button: true,
        label: '$titulo. $subtitulo',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              _icono(icono, _rojo, _rojoClaro),
              const SizedBox(width: 12),
              Expanded(child: _textos(titulo, subtitulo)),
              const Icon(Icons.chevron_right_rounded, color: _textoSecundario, size: 26),
            ]),
          ),
        ),
      );

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
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: 'Volver',
                child: InkWell(
                  onTap: () => Navigator.pop(context),
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
              const SizedBox(height: 20),
              const Text('Privacidad y datos',
                  style: TextStyle(fontFamily: _fuente, fontSize: 21, fontWeight: FontWeight.w700, color: _texto)),
              const SizedBox(height: 4),
              const Text('Documentos, consentimiento y datos.',
                  style: TextStyle(fontFamily: _fuente, fontSize: 14, color: _textoSecundario)),
              const SizedBox(height: 22),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _tituloSeccion('DOCUMENTOS'),
                    _tarjeta([
                      _filaDocumento('Términos y condiciones', terminosYCondiciones),
                      _filaDocumento('Política de privacidad', politicaDePrivacidad),
                    ]),
                    const SizedBox(height: 22),
                    _tituloSeccion('REGISTRO DE ACEPTACIÓN'),
                    _tarjeta([
                      Semantics(
                        label: '$_textoFecha. $_textoVersion',
                        excludeSemantics: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(children: [
                            _icono(Icons.check_circle_outline_rounded, _teal, _tealClaro),
                            const SizedBox(width: 12),
                            Expanded(child: _textos(_textoFecha, _textoVersion)),
                          ]),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 22),
                    _tituloSeccion('TUS DATOS'),
                    _tarjeta([
                      _filaAccion(
                        titulo: 'Retirar consentimiento',
                        subtitulo: 'Dejar de usar la app y borrar sus datos',
                        icono: Icons.do_not_disturb_on_outlined,
                        onTap: () => confirmarBorrarDatos(context, retirarConsentimiento: true),
                      ),
                      _filaAccion(
                        titulo: 'Borrar los datos',
                        subtitulo: 'Eliminar todo lo guardado en este teléfono',
                        icono: Icons.delete_outline_rounded,
                        onTap: () => confirmarBorrarDatos(context),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    const Text('Las dos opciones piden tu PIN y no se pueden deshacer.',
                        style: TextStyle(fontFamily: _fuente, fontSize: 12.5, color: _textoSecundario)),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
