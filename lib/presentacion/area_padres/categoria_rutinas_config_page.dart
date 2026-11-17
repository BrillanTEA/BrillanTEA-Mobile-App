import 'package:flutter/material.dart';

import '../../dominio/rutinas_data.dart';
import '../../dominio/rutinas_service.dart';
import '../comun/dialogo_confirmacion.dart';

/// Rutinas de una categoría: ver, buscar, filtrar (activas o desactivadas) y activar o desactivar
/// una por una o todas a la vez. Al confirmar se pide «¿Guardar los cambios?» y al salir con cambios,
/// «¿Salir sin guardar?» (US1005; Figma «Higiene · 5b, 6, 6b, 7a, 7b, 7c»).
class CategoriaRutinasConfigPage extends StatefulWidget {
  final String categoria;

  const CategoriaRutinasConfigPage({
    super.key,
    required this.categoria,
  });

  @override
  State<CategoriaRutinasConfigPage> createState() =>
      _CategoriaRutinasConfigPageState();
}

class _CategoriaRutinasConfigPageState
    extends State<CategoriaRutinasConfigPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorTealClaro = Color(0xFFDDE9EC);
  static const Color colorVerdeActiva = Color(0xFF4F7A58);
  static const Color colorGrisDesactivada = Color(0xFFB9B2A4);
  static const Color colorDivider = Color(0xFFEDE8DD);

  final RutinasService _rutinasService = RutinasService();
  final TextEditingController _searchController = TextEditingController();

  Set<int> _desactivadas = {};
  bool _cargando = true;

  bool _modoEdicion = false;
  final Map<int, bool> _edicionEstados = {};

  String _filtroTexto = '';
  // 'todas', 'activas', 'desactivadas'
  String _filtroEstado = 'todas';

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

  List<RutinaInfo> get _rutinasCategoria {
    return RutinasCatalogo.porCategoria(widget.categoria);
  }

  int get _totalCategoria => _rutinasCategoria.length;

  int get _activasCategoria {
    if (_modoEdicion) {
      return _rutinasCategoria
          .where((r) => _edicionEstados[r.id] ?? true)
          .length;
    }
    return _rutinasCategoria
        .where((r) => !_desactivadas.contains(r.id))
        .length;
  }

  bool _isRutinaActiva(int id) {
    if (_modoEdicion) {
      return _edicionEstados[id] ?? (!_desactivadas.contains(id));
    }
    return !_desactivadas.contains(id);
  }

  void _iniciarEdicion() {
    final map = <int, bool>{};
    for (final r in _rutinasCategoria) {
      map[r.id] = !_desactivadas.contains(r.id);
    }
    setState(() {
      _edicionEstados.clear();
      _edicionEstados.addAll(map);
      _modoEdicion = true;
    });
  }

  /// Rutinas cuyo estado en edición es distinto del guardado.
  List<int> get _cambios => [
        for (final r in _rutinasCategoria)
          if ((_edicionEstados[r.id] ?? !_desactivadas.contains(r.id)) != !_desactivadas.contains(r.id)) r.id,
      ];

  String _rutinas(int n) => n == 1 ? '1 rutina' : '$n rutinas';

  void _salirDeEdicion() {
    setState(() {
      _edicionEstados.clear();
      _modoEdicion = false;
    });
  }

  Future<void> _cancelarEdicion() async {
    final n = _cambios.length;
    if (n == 0) {
      _salirDeEdicion();
      return;
    }
    final seguir = await mostrarDialogoConfirmacion(
      context,
      tipo: TipoDialogo.aviso,
      titulo: '¿Salir sin guardar?',
      texto: '${n == 1 ? 'Tienes 1 cambio sin guardar' : 'Tienes $n cambios sin guardar'}.\n'
          'Si sales ahora, no se ${n == 1 ? 'aplicará' : 'aplicarán'}.',
      primario: 'Seguir editando',
      secundario: 'Salir sin guardar',
      secundarioRojo: true,
    );
    if (seguir == false && mounted) _salirDeEdicion();
  }

  String _textoConfirmacion(List<int> cambios) {
    final activar = cambios.where((id) => _edicionEstados[id] == true).length;
    final desactivar = cambios.length - activar;
    final cat = widget.categoria;
    if (desactivar == 0) {
      return 'Se ${activar == 1 ? 'activará' : 'activarán'} ${_rutinas(activar)} de $cat.\n'
          'El menor podrá ${activar == 1 ? 'verla' : 'verlas'} en su lista.';
    }
    if (activar == 0) {
      final ninguna = _activasCategoria == 0;
      return 'Se ${desactivar == 1 ? 'desactivará' : 'desactivarán'} ${_rutinas(desactivar)} de $cat.\n'
          '${ninguna ? 'El menor no verá ninguna de esta categoría.' : 'El menor ya no ${desactivar == 1 ? 'la' : 'las'} verá en su lista.'}';
    }
    return 'Se ${desactivar == 1 ? 'desactivará' : 'desactivarán'} ${_rutinas(desactivar)}\n'
        'y se ${activar == 1 ? 'activará' : 'activarán'} ${_rutinas(activar)} de $cat.';
  }

  Future<void> _confirmarEdicion() async {
    final cambios = _cambios;
    if (cambios.isEmpty) {
      _salirDeEdicion();
      return;
    }
    final ok = await mostrarDialogoConfirmacion(
      context,
      tipo: TipoDialogo.guardar,
      titulo: '¿Guardar los cambios?',
      texto: _textoConfirmacion(cambios),
      primario: 'Sí, guardar',
      secundario: 'Seguir editando',
    );
    if (ok != true) return;
    await _rutinasService.setRutinasActivas(_edicionEstados);
    await _cargarConfiguracion();
    _salirDeEdicion();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configuración actualizada con éxito',
            style: TextStyle(fontFamily: 'Atkinson Hyperlegible Next'),
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// «Activar todas» y «Desactivar todas» dejan todas marcadas en modo edición (Figma «6b» y «6»);
  /// se guardan al confirmar con ✓.
  void _marcarTodas(bool activa) {
    setState(() {
      _edicionEstados
        ..clear()
        ..addEntries(_rutinasCategoria.map((r) => MapEntry(r.id, activa)));
      _modoEdicion = true;
    });
  }

  void _activarTodas() => _marcarTodas(true);

  void _desactivarTodas() => _marcarTodas(false);

  void _mostrarMenuLapiz() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menú lápiz',
      barrierColor: const Color(0x73282828), // rgba(40, 40, 40, 0.45)
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 270,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D000000),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _iniciarEdicion();
                    },
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            color: colorTextoPrincipal,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Elegir una por una',
                                  style: TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: colorTextoPrincipal,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Activa o desactiva cada rutina',
                                  style: TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontSize: 12,
                                    color: colorTextoSecundario,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1.5, color: colorDivider),

                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _activarTodas();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.toggle_on_rounded,
                            color: colorTealPrimario,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Activar todas',
                                  style: TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: colorTextoPrincipal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Las $_totalCategoria de ${widget.categoria}',
                                  style: const TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontSize: 12,
                                    color: colorTextoSecundario,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1.5, color: colorDivider),

                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _desactivarTodas();
                    },
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.toggle_off_rounded,
                            color: colorGrisDesactivada,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Desactivar todas',
                                  style: TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: colorTextoPrincipal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Las $_totalCategoria de ${widget.categoria}',
                                  style: const TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontSize: 12,
                                    color: colorTextoSecundario,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarMenuFiltro(BuildContext context) {
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          value: 'activas',
          height: 48,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: colorVerdeActiva,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Activas',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'desactivadas',
          height: 48,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFA59E90),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Desactivadas',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'todas',
          height: 48,
          child: const Row(
            children: [
              Icon(
                Icons.close_rounded,
                size: 16,
                color: colorTealPrimario,
              ),
              SizedBox(width: 10),
              Text(
                'Quitar filtro',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorTealPrimario,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((val) {
      if (val != null) {
        setState(() {
          _filtroEstado = val;
        });
      }
    });
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

    final total = _totalCategoria;
    final activas = _activasCategoria;

    // Filtrar rutinas por texto y por estado (Activas / Desactivadas / Todas)
    final rutinasFiltradas = _rutinasCategoria.where((r) {
      if (_filtroTexto.trim().isNotEmpty) {
        final query = _filtroTexto.trim().toLowerCase();
        if (!r.nombre.toLowerCase().contains(query)) {
          return false;
        }
      }

      final esActiva = _isRutinaActiva(r.id);
      if (_filtroEstado == 'activas' && !esActiva) {
        return false;
      }
      if (_filtroEstado == 'desactivadas' && esActiva) {
        return false;
      }

      return true;
    }).toList();

    return PopScope(
      canPop: !_modoEdicion,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelarEdicion();
      },
      child: Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildTopBar(),
              const SizedBox(height: 20),

              _buildTituloYSubtitulo(activas, total),
              const SizedBox(height: 18),

              _buildBuscadorYFiltro(),
              const SizedBox(height: 16),

              if (_filtroEstado != 'todas')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorTealClaro,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _filtroEstado == 'activas'
                                  ? 'Filtrando: Activas'
                                  : 'Filtrando: Desactivadas',
                              style: const TextStyle(
                                fontFamily: 'Atkinson Hyperlegible Next',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorTealPrimario,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Semantics(button: true, label: 'Cerrar', child: InkWell(
                              onTap: () => setState(() => _filtroEstado = 'todas'),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: colorTealPrimario,
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: rutinasFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: colorGrisDesactivada,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _filtroTexto.isNotEmpty || _filtroEstado != 'todas'
                                  ? 'No se encontraron rutinas con los filtros actuales.'
                                  : 'No hay rutinas en esta categoría.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Atkinson Hyperlegible Next',
                                fontSize: 14,
                                color: colorTextoSecundario,
                              ),
                            ),
                            if (_filtroEstado != 'todas' || _filtroTexto.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _filtroEstado = 'todas';
                                    _filtroTexto = '';
                                    _searchController.clear();
                                  });
                                },
                                child: const Text(
                                  'Restablecer filtros',
                                  style: TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontWeight: FontWeight.w700,
                                    color: colorTealPrimario,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: rutinasFiltradas.length,
                        itemBuilder: (context, index) {
                          final r = rutinasFiltradas[index];
                          final activa = _isRutinaActiva(r.id);
                          return _buildTarjetaRutina(r, activa);
                        },
                      ),
              ),

              if (!_modoEdicion) ...[
                const SizedBox(height: 8),
                _buildLeyenda(),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  // Barra superior:
  // Modo ver: [Volver] .............. [Lápiz]
  // Modo edición: [✕ Cancelar] ....... [✓ Confirmar]
  Widget _buildTopBar() {
    if (_modoEdicion) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(button: true, label: 'Cerrar', child: InkWell(
            onTap: _cancelarEdicion,
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
                child: Icon(Icons.close_rounded, color: colorTextoPrincipal, size: 22),
              ),
            ),
          )),

          Semantics(button: true, label: 'Confirmar', child: InkWell(
            onTap: _confirmarEdicion,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: colorTealPrimario,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.check_rounded, color: Colors.white, size: 24),
              ),
            ),
          )),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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

        Semantics(button: true, label: 'Editar', child: InkWell(
          onTap: _mostrarMenuLapiz,
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
              child: Icon(Icons.edit_outlined, color: colorTextoPrincipal, size: 22),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildTituloYSubtitulo(int activas, int total) {
    if (_modoEdicion) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editar ${widget.categoria}',
            style: const TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorTextoPrincipal,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toca el interruptor de cada rutina',
            style: TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: colorTextoSecundario,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.categoria,
          style: const TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colorTextoPrincipal,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$activas de $total activas',
          style: const TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: colorTextoSecundario,
          ),
        ),
      ],
    );
  }

  Widget _buildBuscadorYFiltro() {
    return Row(
      children: [
        Expanded(
          child: Container(
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
                    decoration: InputDecoration(
                      hintText: 'Buscar en ${widget.categoria}',
                      hintStyle: const TextStyle(
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
        ),
        const SizedBox(width: 12),

        Builder(
          builder: (btnContext) {
            final tieneFiltroActivo = _filtroEstado != 'todas';
            return Semantics(button: true, label: 'Filtrar', child: InkWell(
              onTap: () => _mostrarMenuFiltro(btnContext),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tieneFiltroActivo ? colorTealClaro : const Color(0xFFEFEAE1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: tieneFiltroActivo ? colorTealPrimario : colorBorde,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.filter_alt_outlined,
                    color: tieneFiltroActivo ? colorTealPrimario : colorTextoPrincipal,
                    size: 22,
                  ),
                ),
              ),
            ));
          },
        ),
      ],
    );
  }

  Widget _buildTarjetaRutina(RutinaInfo r, bool activa) {
    final double cardOpacity = activa ? 1.0 : 0.55;
    final Color bgColor = activa ? Colors.white : const Color(0xFFF6F2EA);

    return Opacity(
      opacity: cardOpacity,
      child: Container(
        height: 64,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorBorde, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE4EFE1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Image.asset(
                  r.assetIcono,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    r.fallbackIcon,
                    color: colorTealPrimario,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    r.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorTextoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${r.totalPasos} pasos',
                    style: const TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: colorTextoSecundario,
                    ),
                  ),
                ],
              ),
            ),

            // Derecha:
            // Modo Ver: punto de estado (●)
            // Modo Edición: interruptor Switch
            if (_modoEdicion)
              Switch.adaptive(
                value: activa,
                activeTrackColor: colorTealPrimario,
                onChanged: (val) {
                  setState(() {
                    _edicionEstados[r.id] = val;
                  });
                },
              )
            else
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: activa ? colorVerdeActiva : colorGrisDesactivada,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildLeyenda() {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: colorVerdeActiva,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Activa',
          style: TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontSize: 12,
            color: colorTextoSecundario,
          ),
        ),
        const SizedBox(width: 24),
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: colorGrisDesactivada,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Desactivada',
          style: TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontSize: 12,
            color: colorTextoSecundario,
          ),
        ),
      ],
    );
  }
}
