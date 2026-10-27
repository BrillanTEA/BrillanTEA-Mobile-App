import 'package:flutter/material.dart';

import '../../dominio/rutinas_data.dart';
import '../../dominio/rutinas_service.dart';
import 'categoria_rutinas_config_page.dart';

/// Rutinas activas: categorías con cuántas rutinas tienen activas; al tocar una se configura en detalle.
class RutinasActivasConfigPage extends StatefulWidget {
  const RutinasActivasConfigPage({super.key});

  @override
  State<RutinasActivasConfigPage> createState() => _RutinasActivasConfigPageState();
}

class _RutinasActivasConfigPageState extends State<RutinasActivasConfigPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorFilaFondo = Color(0xFFEFEAE2);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorVerdeBarra = Color(0xFF4F7A58);

  final RutinasService _rutinasService = RutinasService();
  final TextEditingController _searchController = TextEditingController();

  Set<int> _desactivadas = {};
  bool _cargando = true;
  String _filtroTexto = '';

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarConfiguracion() async {
    final des = await _rutinasService.getRutinasDesactivadas();
    if (mounted) {
      setState(() {
        _desactivadas = des;
        _cargando = false;
      });
    }
  }

  int get _totalRutinas => RutinasCatalogo.todasLasRutinas.length;

  int get _totalActivas {
    return _totalRutinas - _desactivadas.length;
  }

  int _activasEnCategoria(CategoriaRutinaInfo cat) {
    return cat.rutinaIds.where((id) => !_desactivadas.contains(id)).length;
  }

  Future<void> _abrirCategoria(String categoria) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoriaRutinasConfigPage(categoria: categoria),
      ),
    );
    // Refrescar al regresar de la categoría
    await _cargarConfiguracion();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: colorFondo,
        body: Center(
          child: CircularProgressIndicator(color: colorTealPrimario),
        ),
      );
    }

    final total = _totalRutinas;
    final activas = _totalActivas;
    final ratio = total > 0 ? (activas / total).clamp(0.0, 1.0) : 0.0;

    // Filtrar categorías según búsqueda (nombre de categoría o nombre de rutina interna)
    final categoriasFiltradas = RutinasCatalogo.categorias.where((cat) {
      if (_filtroTexto.trim().isEmpty) return true;
      final query = _filtroTexto.trim().toLowerCase();

      if (cat.nombre.toLowerCase().contains(query)) return true;

      final rutinasDeCat = RutinasCatalogo.porCategoria(cat.nombre);
      return rutinasDeCat.any((r) => r.nombre.toLowerCase().contains(query));
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
              const SizedBox(height: 20),

              const Text(
                'Rutinas activas',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Elige qué rutinas ve el menor.',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: colorTextoSecundario,
                ),
              ),
              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4EFE1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFD9BE), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$activas de $total activas',
                      style: const TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B3B3B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          width: constraints.maxWidth,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: ratio,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorVerdeBarra,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEAE1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorBorde, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF8E887C),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _filtroTexto = val),
                        style: const TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 15,
                          color: colorTextoPrincipal,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Buscar rutina',
                          hintStyle: TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 15,
                            color: Color(0xFF8E887C),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_filtroTexto.isNotEmpty)
                      Semantics(button: true, label: 'Quitar', child: GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _filtroTexto = '');
                        },
                        child: const Icon(
                          Icons.cancel_rounded,
                          color: Color(0xFF8E887C),
                          size: 18,
                        ),
                      )),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Nunca interruptores directos aquí; tap navega al detalle de la categoría
              Expanded(
                child: categoriasFiltradas.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron categorías o rutinas.',
                          style: TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 14,
                            color: colorTextoSecundario,
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: categoriasFiltradas.length,
                        itemBuilder: (context, index) {
                          final cat = categoriasFiltradas[index];
                          final int totalCat = cat.rutinaIds.length;
                          final int activasCat = _activasEnCategoria(cat);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: colorFilaFondo,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorBorde, width: 1.5),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => _abrirCategoria(cat.nombre),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            cat.icono,
                                            color: colorTealPrimario,
                                            size: 26,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cat.nombre,
                                              style: const TextStyle(
                                                fontFamily: 'Atkinson Hyperlegible Next',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: colorTextoPrincipal,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$activasCat de $totalCat activas',
                                              style: const TextStyle(
                                                fontFamily: 'Atkinson Hyperlegible Next',
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w400,
                                                color: colorTextoSecundario,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: colorTextoSecundario,
                                        size: 24,
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
