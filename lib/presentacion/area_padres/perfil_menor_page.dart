import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dominio/auth_service.dart';
import '../comun/formatters.dart';
import 'perfil_guardado_page.dart';

/// Edición del perfil del niño desde el Área de padres.
class PerfilMenorPage extends StatefulWidget {
  final PerfilNino? perfilInicial;

  const PerfilMenorPage({
    super.key,
    this.perfilInicial,
  });

  @override
  State<PerfilMenorPage> createState() => _PerfilMenorPageState();
}

class _PerfilMenorPageState extends State<PerfilMenorPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorFilaFondo = Color(0xFFEFEAE2);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorTealClaro = Color(0xFFDDE9EC);

  late TextEditingController _nombreCtrl;
  late int _edadSeleccionada;
  late String _sexoSeleccionado; // 'nino' o 'nina'

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(
      text: widget.perfilInicial?.nombre ?? 'Mateo',
    );
    _edadSeleccionada = widget.perfilInicial?.edad ?? 6;
    _sexoSeleccionado = widget.perfilInicial?.avatar ?? 'nino';
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  void _abrirSelectorEdad() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
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
                const SizedBox(height: 18),
                const Text(
                  'Selecciona la edad del menor',
                  style: TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorTextoPrincipal,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Delimitación clínica del estudio: 6 a 10 años.',
                  style: TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 13.5,
                    color: colorTextoSecundario,
                  ),
                ),
                const SizedBox(height: 16),
                for (int edad = 6; edad <= 10; edad++)
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    selected: _edadSeleccionada == edad,
                    selectedTileColor: colorTealClaro.withValues(alpha: 0.5),
                    title: Text(
                      '$edad años',
                      style: TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 16,
                        fontWeight: _edadSeleccionada == edad ? FontWeight.w700 : FontWeight.w500,
                        color: _edadSeleccionada == edad ? colorTealPrimario : colorTextoPrincipal,
                      ),
                    ),
                    trailing: _edadSeleccionada == edad
                        ? const Icon(Icons.check_rounded, color: colorTealPrimario)
                        : null,
                    onTap: () {
                      setState(() => _edadSeleccionada = edad);
                      Navigator.pop(ctx);
                    },
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _guardarPerfil() async {
    final nombre = _nombreCtrl.text.trim().isNotEmpty ? _nombreCtrl.text.trim() : 'Mateo';
    final ninoActualizado = PerfilNino(
      nombre: nombre,
      edad: _edadSeleccionada,
      avatar: _sexoSeleccionado,
    );

    await AuthService().actualizarPerfilNino(ninoActualizado);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PerfilGuardadoPage(nombreNino: nombre),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Semantics(button: true, label: 'Volver', child: InkWell(
                onTap: () => Navigator.maybePop(context),
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
                    child: Icon(Icons.arrow_back_rounded, color: colorTextoPrincipal, size: 22),
                  ),
                ),
              )),
              const SizedBox(height: 14),

              Row(
                children: [
                  Container(
                    width: 24,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorTealPrimario,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: colorBorde,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Perfil del menor',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cuéntanos un poco sobre él o ella para personalizar la app.',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  color: colorTextoSecundario,
                ),
              ),
              const SizedBox(height: 28),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SEXO',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorTextoSecundario,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        height: 52,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorFilaFondo,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: colorBorde, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _sexoSeleccionado = 'nino'),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _sexoSeleccionado == 'nino' ? colorTealPrimario : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Niño',
                                    style: TextStyle(
                                      fontFamily: 'Atkinson Hyperlegible Next',
                                      fontSize: 16,
                                      fontWeight: _sexoSeleccionado == 'nino' ? FontWeight.w700 : FontWeight.w500,
                                      color: _sexoSeleccionado == 'nino' ? Colors.white : colorTextoSecundario,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _sexoSeleccionado = 'nina'),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _sexoSeleccionado == 'nina' ? colorTealPrimario : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Niña',
                                    style: TextStyle(
                                      fontFamily: 'Atkinson Hyperlegible Next',
                                      fontSize: 16,
                                      fontWeight: _sexoSeleccionado == 'nina' ? FontWeight.w700 : FontWeight.w500,
                                      color: _sexoSeleccionado == 'nina' ? Colors.white : colorTextoSecundario,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colorBorde, width: 1.5),
                            ),
                            child: TextField(
                              controller: _nombreCtrl,
                              inputFormatters: [
                                SinTildesFormatter(),
                                FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZñÑ\s\-]")),
                                LengthLimitingTextInputFormatter(30),
                              ],
                              style: const TextStyle(
                                fontFamily: 'Atkinson Hyperlegible Next',
                                fontSize: 16.5,
                                fontWeight: FontWeight.w600,
                                color: colorTextoPrincipal,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 14,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              color: Colors.white,
                              child: const Text(
                                'NOMBRE',
                                style: TextStyle(
                                  fontFamily: 'Atkinson Hyperlegible Next',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colorTealPrimario,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: _abrirSelectorEdad,
                        child: Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colorBorde, width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$_edadSeleccionada años',
                                    style: const TextStyle(
                                      fontFamily: 'Atkinson Hyperlegible Next',
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w600,
                                      color: colorTextoPrincipal,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: colorTextoSecundario,
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 14,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                color: Colors.white,
                                child: const Text(
                                  'EDAD',
                                  style: TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colorTealPrimario,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _guardarPerfil,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorTealPrimario,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
