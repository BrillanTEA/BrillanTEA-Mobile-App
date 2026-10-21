import 'package:flutter/material.dart';

import '../../dominio/auth_service.dart';
import 'perfil_responsable_page.dart';

/// Aviso de privacidad y consentimiento del primer uso. Si el adulto no acepta, no puede continuar.
/// Basado en la Ley N.° 29733 y su reglamento (D.S. 003-2013-JUS), ISO/IEC 27001 y 27701
/// y privacidad desde el diseño (todo se procesa en el dispositivo).
class AvisoPrivacidadPage extends StatefulWidget {
  final bool soloLectura;

  const AvisoPrivacidadPage({
    super.key,
    this.soloLectura = false,
  });

  @override
  State<AvisoPrivacidadPage> createState() => _AvisoPrivacidadPageState();
}

class _AvisoPrivacidadPageState extends State<AvisoPrivacidadPage> {
  static const Color colorFondo = Color(0xFFFAF8F5);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF2C3E50);
  static const Color colorTextoSecundario = Color(0xFF6B7280);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorAzulTitulo = Color(0xFF033878);
  static const Color colorBadgeFondo = Color(0xFFE8F1F5);
  static const Color colorBadgeBorde = Color(0xFFB8D5E5);

  bool _aceptoTerminos = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _aceptarYContinuar() async {
    if (!_aceptoTerminos) return;

    await AuthService().setAcuerdoPrivacidadAceptado(true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PerfilResponsablePage()),
    );
  }

  void _mostrarDialogoRechazo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: Color(0xFFC0392B), size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Consentimiento requerido',
                style: TextStyle(
                  fontFamily: 'Atkinson Hyperlegible Next',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC0392B),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Para proteger la privacidad del menor y cumplir estrictamente con los estándares ISO/IEC 27001 e ISO/IEC 27701, no se puede continuar con el registro sin la aceptación del acuerdo de protección de datos.\n\nPuedes revisar el acuerdo cuando lo desees o regresar a la pantalla principal.',
          style: TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontSize: 14.5,
            height: 1.45,
            color: colorTextoPrincipal,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text(
              'Salir al inicio',
              style: TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                color: Color(0xFF7F8C8D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorTealPrimario,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(
              'Revisar acuerdo',
              style: TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  Semantics(button: true, label: 'Volver', child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 44,
                      height: 44,
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
                      'Protección de Datos',
                      style: TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: colorAzulTitulo,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorBadgeFondo,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorBadgeBorde),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified_user_rounded, color: colorTealPrimario, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'ESTÁNDARES ISO/IEC 27001 · 27701 & LEY 29733',
                            style: TextStyle(
                              fontFamily: 'Atkinson Hyperlegible Next',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: colorTealPrimario,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Acuerdo para el Tratamiento y Protección de Datos Personales',
                      style: TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: colorTextoPrincipal,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'En cumplimiento del marco de seguridad de la información y privacidad desde el diseño, este documento detalla cómo BrillanTEA resguarda la información de tu hogar.',
                      style: TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 14.5,
                        height: 1.4,
                        color: colorTextoSecundario,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _buildSeccionCard(
                      numero: '1',
                      titulo: 'Finalidad Asistencial Exclusiva',
                      subtitulo: 'ISO/IEC 27701 (Cláusula 7.2) · Principio de Finalidad',
                      icono: Icons.assignment_outlined,
                      contenido:
                          'Los datos personales solicitados al adulto responsable (nombres, parentesco, fecha de nacimiento) y al menor (nombre y edad) se recaban con el único propósito de:\n'
                          '• Personalizar la experiencia comunicativa y los pictogramas interactivos (metodologías PECS / TEACCH).\n'
                          '• Configurar el PIN de seguridad y las preguntas estables de recuperación para blindar el Área de Padres frente a accesos accidentales del menor.',
                    ),

                    const SizedBox(height: 14),

                    _buildSeccionCard(
                      numero: '2',
                      titulo: 'Privacidad por Diseño: 100% Local (Edge AI)',
                      subtitulo: 'Sin servidores externos ni transferencia en la nube',
                      icono: Icons.memory_rounded,
                      contenido:
                          'La aplicación opera bajo el principio de «Privacidad por Defecto»:\n'
                          '• Reconocimiento de Objetos (Cámara): Las imágenes captadas son procesadas en tiempo real en la memoria volátil del teléfono mediante modelos embebidos (YOLO / TFLite). No se guardan fotos en disco ni se envían a ningún servidor externo.\n'
                          '• Síntesis de Voz: La locución se genera mediante el motor local del sistema operativo, funcionando plenamente sin conexión a Internet (Offline).',
                    ),

                    const SizedBox(height: 14),

                    _buildSeccionCard(
                      numero: '3',
                      titulo: 'Seguridad Criptográfica de Credenciales',
                      subtitulo: 'ISO/IEC 27001 (Control A.8.24) · Controles de Acceso',
                      icono: Icons.lock_outline_rounded,
                      contenido:
                          'El PIN de acceso nunca se almacena en texto plano. Se protege mediante hashing criptográfico SHA-256 acompañado de una sal (Salt) aleatoria de 16 bytes generada por hardware seguro.\n'
                          'Asimismo, el sistema implementa bloqueo temporal de 5 minutos tras 3 intentos erróneos para prevenir ataques de fuerza bruta.',
                    ),

                    const SizedBox(height: 14),

                    _buildSeccionCard(
                      numero: '4',
                      titulo: 'Control Total y Derechos ARCO',
                      subtitulo: 'Acceso, Rectificación, Cancelación y Oposición',
                      icono: Icons.manage_accounts_outlined,
                      contenido:
                          'El adulto responsable conserva el control absoluto sobre sus datos en todo momento:\n'
                          '• Puede consultar o modificar perfiles desde el Área de Padres.\n'
                          '• Puede restablecer el PIN o eliminar permanentemente todos los registros locales de uso y favoritos desde la opción de Configuración de Cuenta.',
                    ),

                    const SizedBox(height: 20),

                    // Casilla de consentimiento (solo si no es modo lectura)
                    if (!widget.soloLectura) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _aceptoTerminos ? colorTealPrimario : colorBorde,
                            width: _aceptoTerminos ? 2.0 : 1.5,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => setState(() => _aceptoTerminos = !_aceptoTerminos),
                          borderRadius: BorderRadius.circular(10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _aceptoTerminos,
                                activeColor: colorTealPrimario,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (v) => setState(() => _aceptoTerminos = v ?? false),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'He leído, comprendo y acepto expresamente el Acuerdo de Protección de Datos Personales conforme a las normas ISO/IEC 27001, 27701 y Ley 29733.',
                                  style: TextStyle(
                                    fontFamily: 'Atkinson Hyperlegible Next',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                    color: colorTextoPrincipal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: widget.soloLectura
                  ? SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorTealPrimario,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _aceptoTerminos ? _aceptarYContinuar : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorTealPrimario,
                              disabledBackgroundColor: const Color(0xFFC9D5DA),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Aceptar y continuar',
                              style: TextStyle(
                                fontFamily: 'Atkinson Hyperlegible Next',
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _mostrarDialogoRechazo,
                          child: const Text(
                            'No acepto',
                            style: TextStyle(
                              fontFamily: 'Atkinson Hyperlegible Next',
                              fontSize: 15,
                              color: Color(0xFF888888),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionCard({
    required String numero,
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required String contenido,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorBorde, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorBadgeFondo,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(icono, color: colorTealPrimario, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$numero. $titulo',
                      style: const TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: colorTextoPrincipal,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontFamily: 'Atkinson Hyperlegible Next',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorTealPrimario,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            contenido,
            style: const TextStyle(
              fontFamily: 'Atkinson Hyperlegible Next',
              fontSize: 13.5,
              height: 1.42,
              color: Color(0xFF4A4A4A),
            ),
          ),
        ],
      ),
    );
  }
}
