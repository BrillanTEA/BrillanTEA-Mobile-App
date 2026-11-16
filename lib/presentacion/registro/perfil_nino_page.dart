import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dominio/auth_service.dart';
import '../comun/formatters.dart';
import 'creando_espacio_page.dart';

/// Perfil del niño en el registro (de 6 a 10 años, TEA Nivel 2).
class PerfilNinoPage extends StatefulWidget {
  final PerfilAdulto perfilAdulto;

  const PerfilNinoPage({
    super.key,
    required this.perfilAdulto,
  });

  @override
  State<PerfilNinoPage> createState() => _PerfilNinoPageState();
}

class _PerfilNinoPageState extends State<PerfilNinoPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorInput = Color(0xFFF6F6F4);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorBotonDeshabilitado = Color(0xFFC9D5DA);
  static const Color colorPista = Color(0xFF9A968C);

  String _avatarSeleccionado = 'nino'; // 'nino' o 'nina'
  final TextEditingController _nombreCtrl = TextEditingController();
  int _edadSeleccionada = 8;
  String? _error;

  final _filtroTextoSeguro = [
    SinTildesFormatter(),
    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZñÑ\s\-]")),
    LengthLimitingTextInputFormatter(30),
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  bool get _formularioValido => _nombreCtrl.text.trim().isNotEmpty;

  void _continuar() {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Por favor ingresa el nombre o apodo del niño o niña.');
      return;
    }

    final nino = PerfilNino(
      nombre: nombre,
      edad: _edadSeleccionada,
      avatar: _avatarSeleccionado,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreandoEspacioPage(
          perfilAdulto: widget.perfilAdulto,
          perfilNino: nino,
        ),
      ),
    );
  }

  void _abrirSelectorEdad() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorBorde,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edad del niño o niña',
                  style: TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorTextoPrincipal,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Delimitación TEA Nivel 2 (6 a 10 años)',
                  style: TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 14,
                    color: colorTextoSecundario,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5, // 6, 7, 8, 9, 10
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF2F2EE)),
                  itemBuilder: (ctx, i) {
                    final edad = 6 + i;
                    final sel = _edadSeleccionada == edad;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      title: Text(
                        '$edad años',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 16,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? colorTealPrimario : colorTextoPrincipal,
                        ),
                      ),
                      trailing: sel
                          ? const Icon(Icons.check_circle_rounded, color: colorTealPrimario, size: 24)
                          : null,
                      onTap: () {
                        setState(() => _edadSeleccionada = edad);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formValido = _formularioValido;
    final tecladoVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: colorFondo,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Row(
                  children: [
                    Semantics(button: true, label: 'Volver', child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: colorBorde, width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back, color: colorTextoPrincipal, size: 22),
                        ),
                      ),
                    )),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Perfil del niño',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: colorTextoPrincipal,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cuéntanos un poco sobre él o ella para personalizar la app.',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 16,
                          height: 1.4,
                          color: colorTextoSecundario,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Elige un avatar',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 14,
                          color: colorTextoSecundario,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildAvatarCard(
                            tipo: 'nino',
                            etiqueta: 'Niño',
                            assetPath: 'assets/images/avatar_nino.png',
                            esSeleccionado: _avatarSeleccionado == 'nino',
                          ),
                          const SizedBox(width: 20),
                          _buildAvatarCard(
                            tipo: 'nina',
                            etiqueta: 'Niña',
                            assetPath: 'assets/images/avatar_nina.png',
                            esSeleccionado: _avatarSeleccionado == 'nina',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Nombre o apodo del niño o niña',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 14,
                          color: colorTextoSecundario,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: _error != null ? const Color(0xFFFDF7F7) : colorInput,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _error != null ? const Color(0xFFC97469) : colorBorde,
                            width: _error != null ? 1.8 : 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _nombreCtrl,
                          inputFormatters: _filtroTextoSeguro,
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorTextoPrincipal,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Ej. Mateo',
                            hintStyle: TextStyle(color: colorPista, fontSize: 16),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) {
                            if (_error != null) {
                              setState(() => _error = null);
                            }
                          },
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFB3453A)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  fontFamily: 'Atkinson Hyperlegible Next',
                                  color: Color(0xFFB3453A),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 18),

                      const Text(
                        'Edad (6 a 10 años - Delimitación TEA Nivel 2)',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 14,
                          color: colorTextoSecundario,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _abrirSelectorEdad,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: colorInput,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorBorde, width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$_edadSeleccionada años',
                                style: const TextStyle(
                                  fontFamily: 'Atkinson Hyperlegible Next',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorTextoPrincipal,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: colorTextoSecundario, size: 24),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Botón continuar integrado al final del scroll si el teclado está abierto
                      if (tecladoVisible)
                        _buildBotonContinuar(formValido),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Botón Continuar FIJO en la parte inferior (Sticky CTA) solo si el teclado está CERRADO
              if (!tecladoVisible)
                Container(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 12,
                    bottom: MediaQuery.of(context).padding.bottom > 0
                        ? MediaQuery.of(context).padding.bottom + 8
                        : 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        offset: const Offset(0, -3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: _buildBotonContinuar(formValido),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotonContinuar(bool formValido) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: formValido ? _continuar : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: formValido ? colorTealPrimario : colorBotonDeshabilitado,
          disabledBackgroundColor: colorBotonDeshabilitado,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'Continuar',
          style: TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: formValido ? Colors.white : const Color(0xFF8E9598),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCard({
    required String tipo,
    required String etiqueta,
    required String assetPath,
    required bool esSeleccionado,
  }) {
    return InkWell(
      onTap: () => setState(() => _avatarSeleccionado = tipo),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 140,
        height: 166,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          color: colorInput,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: esSeleccionado ? colorTealPrimario : colorBorde,
            width: esSeleccionado ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Image.asset(
                    assetPath,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                if (esSeleccionado)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: colorTealPrimario,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              etiqueta,
              style: const TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorTextoPrincipal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
