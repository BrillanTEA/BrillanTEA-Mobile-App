import 'package:flutter/material.dart';

import '../../dominio/auth_service.dart';
import '../../dominio/premios_service.dart';
import '../premios/premios_page.dart';
import 'cambiar_pin_page.dart';
import 'rutinas_activas_config_page.dart';

/// Configuración de cuenta del responsable: rutinas activas, cambio de PIN y premios.
class ConfiguracionCuentaPage extends StatefulWidget {
  const ConfiguracionCuentaPage({super.key});

  @override
  State<ConfiguracionCuentaPage> createState() => _ConfiguracionCuentaPageState();
}

class _ConfiguracionCuentaPageState extends State<ConfiguracionCuentaPage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorFilaFondo = Color(0xFFEFEAE2);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorTealClaro = Color(0xFFDDE9EC);

  PerfilAdulto? _adulto;
  ConfigPremios? _premios;

  @override
  void initState() {
    super.initState();
    _cargarAdulto();
    _cargarPremios();
  }

  Future<void> _cargarPremios() async {
    final c = await PremiosService().config();
    if (mounted) setState(() => _premios = c);
  }

  String get _subtituloPremios {
    final c = _premios;
    if (c == null) return 'Medallas por rutinas terminadas';
    return c.activados ? 'Meta: ${c.metaSemanal} medallas por semana' : 'Desactivados';
  }

  Future<void> _cargarAdulto() async {
    final a = await AuthService().getPerfilAdulto();
    if (mounted) setState(() => _adulto = a);
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
                'Configuración de cuenta',
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
                'Ajustes que solo puede cambiar el responsable.',
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
                    _buildMenuItem(
                      titulo: 'Rutinas activas',
                      subtitulo: 'Elige cuáles ve el menor',
                      icono: Icons.format_list_bulleted_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RutinasActivasConfigPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildMenuItem(
                      titulo: 'Cambiar PIN',
                      subtitulo: 'Crea un PIN nuevo',
                      icono: Icons.lock_outline_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CambiarPinPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildMenuItem(
                      titulo: 'Premios',
                      subtitulo: _subtituloPremios,
                      icono: Icons.workspace_premium_rounded,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PremiosConfigPage()),
                        );
                        _cargarPremios();
                      },
                    ),
                    const SizedBox(height: 28),

                    if (_adulto != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F7F4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorBorde),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_user_outlined, size: 20, color: colorTealPrimario),
                                SizedBox(width: 8),
                                Text(
                                  'Responsable registrado',
                                  style: TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: colorTextoPrincipal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_adulto!.nombresYApellidos} (${_adulto!.parentesco})',
                              style: const TextStyle(
                                fontFamily: 'Atkinson Hyperlegible Next',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorTextoPrincipal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nacimiento: ${_adulto!.fechaNacimientoTexto} · ${_adulto!.ciudadNacimiento}',
                              style: const TextStyle(
                                fontFamily: 'Atkinson Hyperlegible Next',
                                fontSize: 13,
                                color: colorTextoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required VoidCallback onTap,
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
                decoration: const BoxDecoration(
                  color: colorTealClaro,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icono, color: colorTealPrimario, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
