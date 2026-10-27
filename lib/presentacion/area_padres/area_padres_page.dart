import 'package:flutter/material.dart';

import '../../dominio/accesibilidad_service.dart';
import '../../dominio/auth_service.dart';
import '../../infraestructura/bloqueo_service.dart';
import '../registro/bienvenida_page.dart';
import 'configuracion_cuenta_page.dart';
import 'perfil_menor_page.dart';
import 'seguimiento_page.dart';
import 'tutoriales_page.dart';

/// Área de padres: perfil del menor, configuración, seguimiento, accesibilidad, tutoriales y ayuda.
class AreaPadresPage extends StatefulWidget {
  const AreaPadresPage({super.key});

  @override
  State<AreaPadresPage> createState() => _AreaPadresPageState();
}

class _AreaPadresPageState extends State<AreaPadresPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorFilaFondo = Color(0xFFEFEAE2);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorTealClaro = Color(0xFFDDE9EC);

  final AuthService _auth = AuthService();
  PerfilNino? _nino;
  PerfilAdulto? _adulto;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final n = await _auth.getPerfilNino();
    final a = await _auth.getPerfilAdulto();
    if (mounted) {
      setState(() {
        _nino = n;
        _adulto = a;
      });
    }
  }

  Future<void> _abrirPerfilMenor() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PerfilMenorPage(perfilInicial: _nino),
      ),
    );
    _cargarDatos();
  }

  Future<void> _abrirConfiguracion() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ConfiguracionCuentaPage(),
      ),
    );
    _cargarDatos();
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
              const SizedBox(height: 20),
              const Text(
                'Área de padres',
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
                'Gestiona el perfil, el progreso y la configuración.',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: colorTextoSecundario,
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFilaMenu(
                      titulo: 'Perfil del menor',
                      subtitulo: 'Editar información y preferencias',
                      icono: Icons.person_rounded,
                      onTap: _abrirPerfilMenor,
                    ),
                    const SizedBox(height: 12),

                    _buildFilaMenu(
                      titulo: 'Configuración',
                      subtitulo: _adulto != null
                          ? 'Responsable: ${_adulto!.nombresYApellidos} · PIN y premios'
                          : 'Datos del responsable, PIN y premios',
                      icono: Icons.settings_rounded,
                      onTap: _abrirConfiguracion,
                    ),
                    const SizedBox(height: 12),

                    _buildFilaMenu(
                      titulo: 'Seguimiento',
                      subtitulo: 'Progreso y actividad en cada módulo',
                      icono: Icons.bar_chart_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SeguimientoPage()),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildFilaMenu(
                      titulo: 'Accesibilidad',
                      subtitulo: 'Tamaño de texto, sonido y estímulos',
                      icono: Icons.tune_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AccesibilidadPage(nombreNino: _nino?.nombre ?? 'Mateo'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildFilaMenu(
                      titulo: 'Tutoriales',
                      subtitulo: 'Aprende para qué sirve cada módulo',
                      icono: Icons.play_circle_outline_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TutorialesPage()),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildFilaMenu(
                      titulo: 'Ayuda y soporte',
                      subtitulo: 'Preguntas frecuentes y contacto',
                      icono: Icons.help_outline_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AyudaSoportePage()),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Opción adicional para testing/desarrollo: Restablecer primer uso
                    _buildFilaMenu(
                      titulo: 'Restablecer primer uso',
                      subtitulo: 'Limpiar credenciales y probar flujo de registro inicial',
                      icono: Icons.restart_alt_rounded,
                      colorIconoFondo: const Color(0xFFFDE8E8),
                      colorIcono: Colors.red.shade700,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text(
                              '¿Restablecer primer uso?',
                              style: TextStyle(
                                fontFamily: 'Atkinson Hyperlegible Next',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            content: const Text(
                              'Se borrarán los datos guardados en este dispositivo para validar el flujo completo de inicio y registro de PIN.',
                              style: TextStyle(fontFamily: 'Atkinson Hyperlegible Next'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancelar', style: TextStyle(color: colorTextoSecundario)),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final nav = Navigator.of(context);
                                  await _auth.reiniciarTodo();
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  nav.pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const BienvenidaPage(saltarSplash: true)),
                                    (route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Restablecer', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilaMenu({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required VoidCallback onTap,
    Color? colorIconoFondo,
    Color? colorIcono,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: colorFilaFondo,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorBorde, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorIconoFondo ?? colorTealClaro,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icono, color: colorIcono ?? colorTealPrimario, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colorTextoPrincipal,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: colorTextoSecundario,
                        height: 1.3,
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
    );
  }
}


/// Accesibilidad: tamaño de texto, estímulos, lectura en voz alta, cámara y fijación de pantalla.
class AccesibilidadPage extends StatefulWidget {
  final String nombreNino;

  const AccesibilidadPage({super.key, required this.nombreNino});

  @override
  State<AccesibilidadPage> createState() => _AccesibilidadPageState();
}

class _AccesibilidadPageState extends State<AccesibilidadPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorTealClaro = Color(0xFFDDE9EC);

  final AccesibilidadService _acc = AccesibilidadService();

  @override
  void initState() {
    super.initState();
    _acc.addListener(_actualizar);
    _verificarEstadoBloqueoNativo();
  }

  @override
  void dispose() {
    _acc.removeListener(_actualizar);
    super.dispose();
  }

  void _actualizar() {
    if (mounted) setState(() {});
  }

  Future<void> _verificarEstadoBloqueoNativo() async {
    final activo = await BloqueoService.isLockTaskActive();
    _acc.setPantallaBloqueada(activo);
  }

  Future<void> _toggleBloqueoPantalla(bool activar) async {
    if (activar) {
      final exito = await BloqueoService.startLockTask();
      await _acc.setPantallaBloqueada(true);
      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '🔒 Pantalla fijada (Modo seguro). Para salir, desancla con los botones de tu celular o ingresa con tu PIN.',
                style: TextStyle(fontFamily: 'Atkinson Hyperlegible Next'),
              ),
              backgroundColor: colorTealPrimario,
            ),
          );
        } else {
          // El sistema operativo requiere habilitar Fijar aplicaciones en Ajustes
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Permiso de fijar pantalla',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              content: const Text(
                'El modo seguro ya quedó activado dentro de la aplicación.\n\nPara que Android además bloquee las teclas del sistema y evite salir de la app, debes activar "Fijar aplicaciones" (App Pinning) en los Ajustes de Seguridad de Android.\n\n¿Deseas abrir los Ajustes de Seguridad ahora?',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    BloqueoService.openSecuritySettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorTealPrimario,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Abrir Ajustes de Android'),
                ),
              ],
            ),
          );
        }
      }
    } else {
      await BloqueoService.stopLockTask();
      await _acc.setPantallaBloqueada(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🔓 Modo seguro desactivado.',
              style: TextStyle(fontFamily: 'Atkinson Hyperlegible Next'),
            ),
            backgroundColor: colorTealPrimario,
          ),
        );
      }
    }
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
                    child: Icon(Icons.arrow_back_rounded, color: colorTextoPrincipal, size: 22),
                  ),
                ),
              )),
              const SizedBox(height: 20),
              const Text(
                'Accesibilidad',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ajusta la app según las necesidades de ${widget.nombreNino}.',
                style: const TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorTextoSecundario,
                ),
              ),
              const SizedBox(height: 22),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildTituloSeccion('TEXTO'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorBorde, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tamaño de texto',
                            style: TextStyle(
                              fontFamily: 'Atkinson Hyperlegible Next',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorTextoPrincipal,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 47,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F4EF),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: colorBorde, width: 1.5),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                _buildSegmentoTexto('A', 13, 0),
                                _buildSegmentoTexto('A', 15, 1),
                                _buildSegmentoTexto('A', 17, 2),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F4EF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Vista previa: ',
                                      style: TextStyle(
                                        fontFamily: 'Atkinson Hyperlegible Next',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: colorTextoSecundario,
                                      ),
                                    ),
                                    Text(
                                      _acc.tamanoTextoIndex == 0
                                          ? 'Pequeño (13)'
                                          : (_acc.tamanoTextoIndex == 2
                                              ? 'Grande (17)'
                                              : 'Normal (15)'),
                                      style: const TextStyle(
                                        fontFamily: 'Atkinson Hyperlegible Next',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: colorTealPrimario,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Así se verá el texto en toda la aplicación.',
                                  style: const TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w600,
                                    color: colorTextoPrincipal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    _buildTituloSeccion('ESTÍMULOS'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorBorde, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          _buildFilaToggle(
                            titulo: 'Sonidos de la app',
                            subtitulo: 'Efectos de sonido al tocar botones',
                            icono: Icons.volume_up_rounded,
                            valor: _acc.sonidosApp,
                            onChanged: (v) => _acc.setSonidosApp(v),
                          ),
                          const Divider(height: 1.5, color: colorBorde),
                          _buildFilaToggle(
                            titulo: 'Vibración',
                            subtitulo: 'Respuesta táctil al tocar la pantalla',
                            icono: Icons.vibration_rounded,
                            valor: _acc.vibracion,
                            onChanged: (v) => _acc.setVibracion(v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    _buildTituloSeccion('LECTURA'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorBorde, width: 1.5),
                      ),
                      child: _buildFilaToggle(
                        titulo: 'Leer en voz alta',
                        subtitulo: 'Lee los textos e instrucciones de la app',
                        icono: Icons.record_voice_over_rounded,
                        valor: _acc.leerVozAlta,
                        onChanged: (v) => _acc.setLeerVozAlta(v),
                      ),
                    ),
                    const SizedBox(height: 22),

                    _buildTituloSeccion('CÁMARA'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorBorde, width: 1.5),
                      ),
                      child: _buildFilaToggle(
                        titulo: 'Tutorial de la cámara',
                        subtitulo: 'Explica cómo usar la cámara',
                        icono: Icons.camera_alt_rounded,
                        valor: _acc.tutorialCamara,
                        onChanged: (v) => _acc.setTutorialCamara(v),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Protección y bloqueo de pantalla (US905, US906)
                    _buildTituloSeccion('PROTECCIÓN DE ANDROID'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorBorde, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          _buildFilaToggle(
                            titulo: 'Fijar pantalla (Modo seguro)',
                            subtitulo: 'Evita que el menor salga de la aplicación',
                            icono: Icons.screen_lock_portrait_rounded,
                            valor: _acc.pantallaBloqueada,
                            onChanged: _toggleBloqueoPantalla,
                          ),
                          const Divider(height: 1.5, color: colorBorde),
                          _buildFilaBoton(
                            titulo: 'Ajustes de seguridad de Android',
                            subtitulo: 'Configura la solicitud de PIN al dejar de fijar',
                            icono: Icons.security_rounded,
                            onTap: BloqueoService.openSecuritySettings,
                          ),
                          const Divider(height: 1.5, color: colorBorde),
                          _buildFilaBoton(
                            titulo: 'Ajustes de accesibilidad de Android',
                            subtitulo: 'Gestionar permisos y servicios de accesibilidad',
                            icono: Icons.accessibility_new_rounded,
                            onTap: BloqueoService.openAccessibilitySettings,
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildTituloSeccion(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        style: const TextStyle(
          fontFamily: 'Atkinson Hyperlegible Next',
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: colorTextoSecundario,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSegmentoTexto(String texto, double fontSize, int index) {
    final seleccionado = _acc.tamanoTextoIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () async {
          await _acc.setTamanoTextoIndex(index);
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Tamaño de fuente cambiado a: $texto',
                  style: const TextStyle(fontFamily: 'Atkinson Hyperlegible Next'),
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: colorTealPrimario,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          decoration: BoxDecoration(
            color: seleccionado ? colorTealPrimario : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              texto,
              style: TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: seleccionado ? Colors.white : colorTextoSecundario,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilaToggle({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!valor),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: colorTealClaro,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icono, color: colorTealPrimario, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: colorTextoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: colorTextoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: valor,
              onChanged: onChanged,
              activeThumbColor: colorTealPrimario,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaBoton({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: colorTealClaro,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icono, color: colorTealPrimario, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: colorTextoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontFamily: 'Atkinson Hyperlegible Next',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: colorTextoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorTextoSecundario),
          ],
        ),
      ),
    );
  }
}

/// Ayuda y soporte: preguntas frecuentes, contacto y acerca de.
class AyudaSoportePage extends StatelessWidget {
  const AyudaSoportePage({super.key});

  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorTealClaro = Color(0xFFDDE9EC);

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
                    child: Icon(Icons.arrow_back_rounded, color: colorTextoPrincipal, size: 22),
                  ),
                ),
              )),
              const SizedBox(height: 20),
              const Text(
                'Ayuda y soporte',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Resolvemos tus dudas sobre la app.',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorTextoSecundario,
                ),
              ),
              const SizedBox(height: 22),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildTituloSeccion('PREGUNTAS FRECUENTES'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorBorde, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          _buildPreguntaItem(
                            context,
                            pregunta: '¿Cómo cambio el PIN de acceso?',
                            respuesta:
                                'Ingresa al Área de Padres con tu PIN actual y selecciona la opción "Configuración". Podrás ingresar tu PIN actual y definir uno nuevo de 4 dígitos.',
                          ),
                          const Divider(height: 1.5, color: colorBorde),
                          _buildPreguntaItem(
                            context,
                            pregunta: '¿Cómo edito el perfil de mi hijo/a?',
                            respuesta:
                                'En el menú del Área de Padres, presiona "Perfil del menor". Podrás modificar su nombre o apodo, edad y avatar personalizado.',
                          ),
                          const Divider(height: 1.5, color: colorBorde),
                          _buildPreguntaItem(
                            context,
                            pregunta: '¿Los datos de mi hijo/a están seguros?',
                            respuesta:
                                'Sí. Toda la información, progreso y personalización se guardan localmente en el dispositivo con almacenamiento seguro, sin subir datos sensibles a internet.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    _buildTituloSeccion('CONTÁCTANOS'),
                    Semantics(
                      button: true,
                      label: 'Escribir a soporte, ${BloqueoService.correoSoporte}',
                      excludeSemantics: true,
                      child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final ok = await BloqueoService.abrirCorreoSoporte();
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No hay una app de correo instalada.')),
                          );
                        }
                      },
                      child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorBorde, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 43,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: colorTealClaro,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.mail_outline_rounded, color: colorTealPrimario, size: 20),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  BloqueoService.correoSoporte,
                                  style: TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: colorTealPrimario,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Escríbenos y te responderemos pronto',
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
                    ),
                    const SizedBox(height: 22),

                    _buildTituloSeccion('ACERCA DE'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorBorde, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          _buildFilaSimple(
                            context,
                            titulo: 'Términos y condiciones',
                            contenido:
                                'Esta aplicación es parte del proyecto de investigación y tesis para soporte de comunicación y rutinas en niños con TEA Nivel 2.',
                          ),
                          const Divider(height: 1.5, color: colorBorde),
                          _buildFilaSimple(
                            context,
                            titulo: 'Política de privacidad',
                            contenido:
                                'Los datos son tratados con estricta confidencialidad clínica y no se comparten con terceros.',
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildTituloSeccion(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        style: const TextStyle(
          fontFamily: 'Atkinson Hyperlegible Next',
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: colorTextoSecundario,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPreguntaItem(
    BuildContext context, {
    required String pregunta,
    required String respuesta,
  }) {
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        pregunta,
        style: const TextStyle(
          fontFamily: 'Atkinson Hyperlegible Next',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: colorTextoPrincipal,
        ),
      ),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      children: [
        Text(
          respuesta,
          style: const TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontSize: 13,
            color: colorTextoSecundario,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFilaSimple(
    BuildContext context, {
    required String titulo,
    required String contenido,
  }) {
    return ListTile(
      title: Text(
        titulo,
        style: const TextStyle(
          fontFamily: 'Atkinson Hyperlegible Next',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: colorTextoPrincipal,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: colorTextoSecundario, size: 14),
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(titulo),
            content: Text(contenido),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
          ),
        );
      },
    );
  }
}
