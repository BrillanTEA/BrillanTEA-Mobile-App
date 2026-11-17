import 'package:flutter/material.dart';

import '../../dominio/auth_service.dart';
import '../../dominio/sesion_calma.dart';
import '../../infraestructura/modo_compilacion.dart';
import '../area_padres/area_padres_page.dart';
import '../area_padres/login_pin_page.dart';
import '../calma/calma_page.dart';
import '../camara/detector_page.dart';
import '../comunicacion/comunicacion_page.dart';
import '../registro/bienvenida_page.dart';
import '../rutinas/rutinas_categorias_page.dart';
import '../situaciones/situaciones_page.dart';
import '../vocabulario/emociones_page.dart';
import '../vocabulario/favoritos_page.dart';
import '../vocabulario/vocabulario_page.dart';

/// Pantalla de inicio con los 7 módulos.
class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFEDE8E0);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);

  int _tabSeleccionado = 0; // 0: Inicio, 1: Favoritos

  void _navegarA(Widget pagina) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => pagina),
    );
  }

  void _abrirAreaPadresConPin() {
    _navegarA(
      const LoginPinPage(
        destinoTrasPin: AreaPadresPage(),
      ),
    );
  }

  Future<void> _resetOnboarding() async {
    Navigator.pop(context); // Cerrar drawer
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Restablecer onboarding',
          style: TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          '¿Estás seguro de que deseas borrar todos los datos y comenzar el flujo de registro desde cero?',
          style: TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: colorTextoSecundario)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Restablecer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await AuthService().reiniciarTodo();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BienvenidaPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _tabSeleccionado,
        children: [
          _buildInicioBody(),
          FavoritosPage(
            onBack: () => setState(() => _tabSeleccionado = 0),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: colorBorde, width: 1.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _tabSeleccionado = 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _tabSeleccionado == 0 ? Icons.home_rounded : Icons.home_outlined,
                        size: 26,
                        color: _tabSeleccionado == 0 ? colorTealPrimario : colorTextoSecundario,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Inicio',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _tabSeleccionado == 0 ? colorTealPrimario : colorTextoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _tabSeleccionado = 1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _tabSeleccionado == 1 ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 26,
                        color: _tabSeleccionado == 1 ? colorTealPrimario : colorTextoSecundario,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Favoritos',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _tabSeleccionado == 1 ? colorTealPrimario : colorTextoSecundario,
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
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'BrillanTEA',
                    style: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colorTextoPrincipal,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Menú principal',
                    style: TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 13,
                      color: colorTextoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: colorBorde, height: 1),
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded, color: colorTextoPrincipal),
              title: const Text(
                'Área de padres (PIN)',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: const Text(
                'Gestión de rutinas, reportes y PIN',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 12,
                  color: colorTextoSecundario,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _abrirAreaPadresConPin();
              },
            ),
            // Solo en la versión QA. En la oficial el niño no ve ninguna opción para borrar (US1206).
            if (kModoQA)
            ListTile(
              leading: const Icon(Icons.restart_alt_rounded, color: Color(0xFFD32F2F)),
              title: const Text(
                'Restablecer onboarding (QA)',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFFD32F2F),
                ),
              ),
              subtitle: const Text(
                'Borrar todo y comenzar de 0 el flujo',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 12,
                  color: colorTextoSecundario,
                ),
              ),
              onTap: _resetOnboarding,
            ),
          ],
        ),
      ),
    );
  }

  void _abrirSituaciones() {
    _navegarA(SituacionesPage(
      onIrInicio: () => Navigator.pop(context),
      onIrFavoritos: () {
        Navigator.pop(context);
        setState(() => _tabSeleccionado = 1);
      },
    ));
  }

  void _abrirCalma() {
    SesionCalma.iniciar();
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: CalmaPage.ruta),
      builder: (_) => CalmaPage(
        onIrInicio: () => Navigator.of(context).popUntil((r) => r.isFirst),
        onIrFavoritos: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          setState(() => _tabSeleccionado = 1);
        },
      ),
    ));
  }

  /// Inicio · 7 módulos: Cámara destacada arriba y una
  /// cuadrícula de 2 columnas con Comunicación, Vocabulario, Rutinas,
  /// Emociones, Situaciones y Calma.
  Widget _buildInicioBody() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (ctx) => Semantics(button: true, label: 'Menú', child: InkWell(
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                      borderRadius: BorderRadius.circular(24),
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.menu_rounded, size: 30, color: colorTextoPrincipal),
                      ),
                    )),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola!',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: colorTextoPrincipal,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Elige lo que quieres hacer.',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: colorTextoSecundario,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildModuloCard(
              titulo: 'Cámara',
              assetImage: 'assets/images/home_camara.png',
              colorFondo: const Color(0xFFB06B47),
              colorTexto: Colors.white,
              altura: 88,
              fontSize: 21,
              imagenWidth: 94,
              imagenHeight: 65,
              onTap: () => _navegarA(const DetectorPage()),
            ),

            const SizedBox(height: 10),

            _filaModulos(
              _buildModuloTile(
                titulo: 'Comunicación',
                assetImage: 'assets/images/home_comunicacion.png',
                colorFondo: const Color(0xFFE3EEF2),
                imagenWidth: 107,
                imagenHeight: 86,
                onTap: () => _navegarA(const ComunicacionPage()),
              ),
              _buildModuloTile(
                titulo: 'Vocabulario',
                assetImage: 'assets/images/home_vocabulario.png',
                colorFondo: const Color(0xFFF4E6ED),
                onTap: () => _navegarA(const VocabularioPage()),
              ),
            ),
            const SizedBox(height: 10),
            _filaModulos(
              _buildModuloTile(
                titulo: 'Rutinas',
                assetImage: 'assets/images/home_rutinas.png',
                colorFondo: const Color(0xFFE3EFE3),
                onTap: () => _navegarA(const RutinasCategoriasPage()),
              ),
              _buildModuloTile(
                titulo: 'Emociones',
                assetImage: 'assets/images/home_emociones.png',
                colorFondo: const Color(0xFFECE8F4),
                onTap: () => _navegarA(const EmocionesPage()),
              ),
            ),
            const SizedBox(height: 10),
            _filaModulos(
              _buildModuloTile(
                titulo: 'Situaciones',
                assetImage: 'assets/images/home_situaciones.png',
                colorFondo: const Color(0xFFF5EEDD),
                onTap: _abrirSituaciones,
              ),
              _buildModuloTile(
                titulo: 'Calma',
                assetImage: 'assets/images/home_calma.png',
                colorFondo: const Color(0xFFE3EFED),
                imagenWidth: 88,
                imagenHeight: 76,
                onTap: _abrirCalma,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaModulos(Widget izquierda, Widget derecha) {
    return Row(
      children: [
        Expanded(child: izquierda),
        const SizedBox(width: 10),
        Expanded(child: derecha),
      ],
    );
  }

  /// Tarjeta cuadrada de la cuadrícula (159 × 140 en Figma): ilustración arriba
  /// a la izquierda, título abajo y botón blanco con flecha abajo a la derecha.
  Widget _buildModuloTile({
    required String titulo,
    required String assetImage,
    required Color colorFondo,
    required VoidCallback onTap,
    double imagenWidth = 100,
    double imagenHeight = 70,
  }) {
    return Semantics(
      button: true,
      label: titulo,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorFondo,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: imagenWidth,
                height: imagenHeight,
                child: Image.asset(
                  assetImage,
                  fit: BoxFit.contain,
                  alignment: Alignment.topLeft,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.image_outlined,
                    size: 36,
                    color: colorTextoPrincipal,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorTextoPrincipal,
                      ),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1)),
                      ],
                    ),
                    child: const Icon(Icons.chevron_right_rounded, size: 22, color: colorTextoPrincipal),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuloCard({
    required String titulo,
    required String assetImage,
    required Color colorFondo,
    required Color colorTexto,
    required double altura,
    required double fontSize,
    required double imagenWidth,
    required double imagenHeight,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: altura,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            SizedBox(
              width: imagenWidth,
              height: imagenHeight,
              child: Image.asset(
                assetImage,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.image_outlined,
                  size: 36,
                  color: colorTextoPrincipal,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: colorTexto,
                ),
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000), // rgba(0, 0, 0, 0.08)
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: colorTextoPrincipal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
