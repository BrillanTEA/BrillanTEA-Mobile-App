import 'package:flutter/material.dart';

import 'rutinas_page.dart';

/// Lista de categorías de rutinas (entrada del módulo Rutinas).
class RutinasCategoriasPage extends StatefulWidget {
  final VoidCallback? onBack;

  const RutinasCategoriasPage({super.key, this.onBack});

  @override
  State<RutinasCategoriasPage> createState() => _RutinasCategoriasPageState();
}

class _RutinasCategoriasPageState extends State<RutinasCategoriasPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFF3D6D7E);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorTealClaro = Color(0xFFDDE9EC);
  static const Color colorIconoFondo = Color(0xFFE5EFE3);

  final TextEditingController _searchCtrl = TextEditingController();
  String _filtro = '';

  final List<Map<String, dynamic>> _categorias = const [
    {
      'nombre': 'Higiene',
      'subtitulo': '2 rutinas',
      'icono': Icons.water_drop_rounded,
      'colorFondo': colorTealClaro,
    },
    {
      'nombre': 'Ropa',
      'subtitulo': '1 rutina',
      'icono': Icons.checkroom_rounded,
      'colorFondo': Colors.white,
    },
    {
      'nombre': 'Comida',
      'subtitulo': '1 rutina',
      'icono': Icons.restaurant_rounded,
      'colorFondo': Colors.white,
    },
    {
      'nombre': 'Hogar',
      'subtitulo': '1 rutina',
      'icono': Icons.home_rounded,
      'colorFondo': Colors.white,
    },
    {
      'nombre': 'Juegos',
      'subtitulo': 'Todas las rutinas',
      'icono': Icons.extension_rounded,
      'colorFondo': Colors.white,
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _abrirCategoria(String categoria) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RutinasPage(
          categoriaInicial: categoria == 'Juegos' ? null : categoria,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriasFiltradas = _categorias.where((c) {
      if (_filtro.isEmpty) return true;
      return (c['nombre'] as String).toLowerCase().contains(_filtro.toLowerCase());
    }).toList();

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
                onTap: widget.onBack ?? () => Navigator.maybePop(context),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDDD6C9), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back_rounded, color: colorTextoPrincipal, size: 22),
                  ),
                ),
              )),
              const SizedBox(height: 20),

              const Text(
                'Categoría de Rutinas',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),

              const Text(
                'Elige qué quieres hacer.',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: colorTextoSecundario,
                ),
              ),
              const SizedBox(height: 18),

              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2ECE4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDD6C9), width: 1.5),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _filtro = val.trim()),
                  style: const TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 15.5,
                    color: colorTextoPrincipal,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Buscar categoría',
                    hintStyle: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 15,
                      color: Color(0xFF8E8A83),
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF6B6B66)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: categoriasFiltradas.length,
                  itemBuilder: (context, index) {
                    final cat = categoriasFiltradas[index];
                    final String nombre = cat['nombre'] as String;
                    final String subtitulo = cat['subtitulo'] as String;
                    final IconData icono = cat['icono'] as IconData;
                    final Color cardBg = cat['colorFondo'] as Color;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colorBorde, width: 2.0),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _abrirCategoria(nombre),
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: colorIconoFondo,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      icono,
                                      color: colorTealPrimario,
                                      size: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nombre,
                                        style: const TextStyle(
                                          fontFamily: 'Atkinson Hyperlegible Next',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: colorTextoPrincipal,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitulo,
                                        style: const TextStyle(
                                          fontFamily: 'Atkinson Hyperlegible Next',
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w400,
                                          color: colorTextoSecundario,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: colorTextoPrincipal,
                                  size: 26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
