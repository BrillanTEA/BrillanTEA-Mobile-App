import 'package:flutter/material.dart';

import '../../dominio/auth_service.dart';
import '../../dominio/registro_uso_service.dart';
import '../../dominio/reporte_service.dart';
import '../../infraestructura/servicio_voz.dart';

/// Seguimiento: uso de los últimos 7 días comparado con los 7 anteriores (RegistroUsoService, SQLite).
class SeguimientoPage extends StatefulWidget {
  final VoidCallback? onBack;

  const SeguimientoPage({super.key, this.onBack});

  @override
  State<SeguimientoPage> createState() => _SeguimientoPageState();
}

class _SeguimientoPageState extends State<SeguimientoPage> {
  // Colores del Figma
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorTealClaro = Color(0xFFDDE9EC);
  static const Color colorLavandaFondo = Color(0xFFB3A6D1);
  static const Color colorLavandaTrazo = Color(0xFF7C6BA0);
  static const Color colorVerdeFondo = Color(0xFFC7DBC5);
  static const Color colorVerdeTrazo = Color(0xFF5E8C68);

  final ServicioVoz _tts = ServicioVoz();
  final RegistroUsoService _registro = RegistroUsoService();

  ResumenSeguimiento? _act;
  ResumenSeguimiento? _ant;
  List<NotaEspecialista> _notas = [];
  String _nombre = '';
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _cargar();
    ReporteService.limpiarViejos();
  }

  Future<void> _cargar() async {
    final nino = await AuthService().getPerfilNino();
    final (act, ant) = await ResumenSeguimiento.semanaActualYAnterior();
    final notas = await _registro.notas();
    if (!mounted) return;
    setState(() {
      _nombre = nino?.nombre ?? '';
      _act = act;
      _ant = ant;
      _notas = notas;
    });
  }

  String get _nombreONino => _nombre.isNotEmpty ? _nombre : 'tu hijo o hija';

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  void _hablar(String texto) async {
    try {
      await _tts.stop();
      await _tts.speak(texto);
    } catch (_) {}
  }

  void _abrirDialogoNota() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).viewPadding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nota para el especialista',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorTextoPrincipal,
                    ),
                  ),
                  IconButton(tooltip: 'Cerrar', 
                    icon: const Icon(Icons.close, color: colorTextoSecundario),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Registra observaciones sensoriales, de conducta o comunicación que puedan ser útiles para el terapeuta.',
                style: TextStyle(
                  fontSize: 13,
                  color: colorTextoSecundario,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Ej: Mostró iniciativa al pedir agua con el pictograma...',
                  hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                  contentPadding: const EdgeInsets.all(12),
                  filled: true,
                  fillColor: const Color(0xFFF9F9F8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: colorBorde, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: colorTealPrimario, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () async {
                    final txt = controller.text.trim();
                    if (txt.isNotEmpty) {
                      Navigator.pop(ctx);
                      await _registro.agregarNota(txt);
                      await _cargar();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Nota guardada correctamente'),
                          backgroundColor: colorTealPrimario,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorTealPrimario,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Guardar nota',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _descargarReporte() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.assignment_turned_in_outlined, color: colorTealPrimario),
            SizedBox(width: 8),
            Text(
              'Reporte de seguimiento',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colorTextoPrincipal,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de los últimos 7 días para $_nombreONino:',
              style: const TextStyle(fontSize: 13, color: colorTextoSecundario),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorBorde),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Rutinas completadas: ${_act?.rutinasCompletadas ?? 0} de ${_act?.rutinasIniciadas ?? 0} iniciadas',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colorTextoPrincipal)),
                  const SizedBox(height: 4),
                  Text('• Peticiones: ${_act?.peticiones ?? 0}',
                      style: const TextStyle(fontSize: 12.5, color: colorTextoPrincipal)),
                  const SizedBox(height: 4),
                  Text(
                      _act?.emocionFrecuente == null
                          ? '• Emociones: sin registros'
                          : '• Emoción más frecuente: ${_act!.emocionFrecuente} (${_act!.emocionFrecuenteVeces}×)',
                      style: const TextStyle(fontSize: 12.5, color: colorTextoPrincipal)),
                  const SizedBox(height: 4),
                  Text(
                      (_act?.masUsados.isEmpty ?? true)
                          ? '• Lo más usado: sin registros'
                          : '• Lo más usado: "${_act!.masUsados.first.key}" (${_act!.masUsados.first.value}×)',
                      style: const TextStyle(fontSize: 12.5, color: colorTextoPrincipal)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Notas del cuidador registradas: ${_notas.length}',
              style: const TextStyle(fontSize: 12, color: colorTextoSecundario, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            const Text(
              'El PDF incluye solo el nombre o apodo, la edad y estos conteos. No incluye imágenes. '
              'Se comparte únicamente con la app que elijas. La aplicación no guarda una copia del reporte: '
              'envíalo o guárdalo en tus archivos para conservarlo.',
              style: TextStyle(fontSize: 11.5, color: colorTextoSecundario, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: colorTextoSecundario)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _exportar();
            },
            icon: const Icon(Icons.share_outlined, size: 18, color: Colors.white),
            label: const Text('Exportar', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorTealPrimario,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportar() async {
    if (_exportando) return;
    setState(() => _exportando = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ReporteService.generarYCompartir();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('No se pudo generar el reporte: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBotonVolver(),

              const SizedBox(height: 20),

              _buildEncabezado(),

              const SizedBox(height: 20),

              _buildFila2Columnas(),

              const SizedBox(height: 14),

              _buildTarjetaComparativo(),

              const SizedBox(height: 14),

              _buildTarjetaPictogramas(),

              const SizedBox(height: 14),

              _buildTarjetaNotaEspecialista(),

              if (_notas.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildListaNotas(),
              ],

              const SizedBox(height: 16),

              _buildBotonDescargarReporte(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotonVolver() {
    return Semantics(button: true, label: 'Volver', child: InkWell(
      onTap: () {
        if (widget.onBack != null) {
          widget.onBack!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
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
          child: Icon(
            Icons.arrow_back,
            color: colorTextoPrincipal,
            size: 22,
          ),
        ),
      ),
    ));
  }

  Widget _buildEncabezado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seguimiento',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colorTextoPrincipal,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Regulación emocional y rutinas de $_nombreONino. Últimos 7 días.',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colorTextoSecundario,
          ),
        ),
      ],
    );
  }

  Widget _buildFila2Columnas() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 128,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorBorde, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RUTINAS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorTextoSecundario,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  '${_act?.rutinasCompletadas ?? 0}/${_act?.rutinasIniciadas ?? 0}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colorTextoPrincipal,
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 8,
                    width: double.infinity,
                    color: colorTealClaro,
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: (_act == null || _act!.rutinasIniciadas == 0)
                          ? 0.0
                          : (_act!.rutinasCompletadas / _act!.rutinasIniciadas).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorTealPrimario,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
                const Text(
                  'completadas de las iniciadas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: colorTextoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Container(
            height: 128,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorBorde, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'EMOCIÓN FRECUENTE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorTextoSecundario,
                    letterSpacing: 0.6,
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: colorLavandaFondo,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(20, 20),
                      painter: _CalmFacePainter(color: colorLavandaTrazo),
                    ),
                  ),
                ),
                Text(
                  _act?.emocionFrecuente ?? 'Sin registros',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorTextoPrincipal,
                  ),
                ),
                Text(
                  _act?.emocionFrecuente == null ? 'en los últimos 7 días' : '${_act!.emocionFrecuenteVeces} veces en 7 días',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: colorTextoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaComparativo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorBorde, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COMPARADO CON LA SEMANA PASADA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorTextoSecundario,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          _filaComparacion(
            actual: _act?.rutinasCompletadas ?? 0,
            anterior: _ant?.rutinasCompletadas ?? 0,
            texto: 'rutinas completadas',
            subirEsBueno: true,
          ),
          const SizedBox(height: 10),
          _filaComparacion(
            actual: _act?.peticiones ?? 0,
            anterior: _ant?.peticiones ?? 0,
            texto: 'peticiones con pictogramas',
            subirEsBueno: true,
          ),
          const SizedBox(height: 10),
          _filaComparacion(
            actual: _act?.momentosDificiles ?? 0,
            anterior: _ant?.momentosDificiles ?? 0,
            texto: 'momentos difíciles registrados (triste, enojado, asustado, nervioso)',
            subirEsBueno: false,
          ),
        ],
      ),
    );
  }

  /// Compara el valor de los últimos 7 días con los 7 anteriores.
  Widget _filaComparacion({
    required int actual,
    required int anterior,
    required String texto,
    required bool subirEsBueno,
  }) {
    final d = actual - anterior;
    final destacado = d == 0 ? 'Igual' : (d > 0 ? '+$d' : '$d');
    final bueno = d == 0 ? null : (d > 0) == subirEsBueno;
    return _buildFilaDelta(
      destacado: destacado,
      texto: ' $texto ($actual esta semana, $anterior la anterior)',
      subiendo: d == 0 ? null : d > 0,
      bueno: bueno,
    );
  }

  Widget _buildFilaDelta({required String destacado, required String texto, bool? subiendo, bool? bueno}) {
    // Verde = mejora, ámbar = empeora, gris = sin cambio
    final fondo = bueno == null ? const Color(0xFFE8E6E1) : (bueno ? colorVerdeFondo : const Color(0xFFF1DDB8));
    final trazo = bueno == null ? colorTextoSecundario : (bueno ? colorVerdeTrazo : const Color(0xFFA06A1B));
    final icono = subiendo == null ? Icons.remove : (subiendo ? Icons.expand_less : Icons.expand_more);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: fondo,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icono,
              size: 16,
              color: trazo,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: colorTextoPrincipal,
                height: 1.25,
              ),
              children: [
                if (destacado.isNotEmpty)
                  TextSpan(
                    text: destacado,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                TextSpan(text: texto),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaPictogramas() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorBorde, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pictogramas más usados',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: colorTextoPrincipal,
            ),
          ),
          const SizedBox(height: 6),
          if (_act == null || _act!.masUsados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Todavía no hay pictogramas usados en los últimos 7 días.',
                style: TextStyle(fontSize: 12.5, color: colorTextoSecundario),
              ),
            )
          else
            for (var i = 0; i < _act!.masUsados.length && i < 3; i++) ...[
              if (i > 0) const Divider(color: colorBorde, thickness: 1, height: 18),
              _buildFilaPictograma(
                rank: i + 1,
                frase: '"${_act!.masUsados[i].key}"',
                conteo: '${_act!.masUsados[i].value}×',
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildFilaPictograma({
    required int rank,
    required String frase,
    required String conteo,
  }) {
    return InkWell(
      onTap: () {
        _hablar(frase.replaceAll('"', ''));
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorTextoSecundario,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                frase,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorTextoPrincipal,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorTealClaro.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                conteo,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorTealPrimario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaNotaEspecialista() {
    return InkWell(
      onTap: _abrirDialogoNota,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorBorde, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: colorTealClaro,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.description_outlined,
                  color: colorTealPrimario,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Agregar nota para el\nespecialista',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: colorTextoPrincipal,
                  height: 1.25,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: colorTextoSecundario,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaNotas() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorBorde.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.notes_rounded, size: 14, color: colorTealPrimario),
              SizedBox(width: 6),
              Text(
                'ÚLTIMA NOTA REGISTRADA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colorTealPrimario,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _notas.first.texto,
            style: const TextStyle(
              fontSize: 12,
              color: colorTextoPrincipal,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonDescargarReporte() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _exportando ? null : _descargarReporte,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorTealPrimario,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.file_download_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _exportando ? 'Generando reporte…' : 'Descargar reporte',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter personalizado para el rostro sereno / tranquilo de Figma
class _CalmFacePainter extends CustomPainter {
  final Color color;

  const _CalmFacePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 1.0;

    // Círculo exterior de la cara
    canvas.drawCircle(center, radius, strokePaint);

    // Ojos
    final leftEye = Offset(center.dx - 4.0, center.dy - 2.5);
    final rightEye = Offset(center.dx + 4.0, center.dy - 2.5);
    canvas.drawCircle(leftEye, 1.2, fillPaint);
    canvas.drawCircle(rightEye, 1.2, fillPaint);

    // Boca serena / relajada (línea suave ligeramente curva)
    final mouthPath = Path();
    mouthPath.moveTo(center.dx - 3.5, center.dy + 3.0);
    mouthPath.quadraticBezierTo(
      center.dx,
      center.dy + 4.5,
      center.dx + 3.5,
      center.dy + 3.0,
    );
    canvas.drawPath(mouthPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CalmFacePainter oldDelegate) =>
      oldDelegate.color != color;
}
