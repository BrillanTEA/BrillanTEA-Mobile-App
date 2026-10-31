import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'auth_service.dart';
import 'registro_uso_service.dart';

/// Generador de Reportes (RF-15): crea el PDF en el almacenamiento privado de la app,
/// abre la hoja de compartir de Android y borra los reportes viejos.
/// Contenido mínimo: primer nombre o apodo, edad y métricas de uso. Sin imágenes.
class ReporteService {
  static const String _prefijo = 'reporte_brillantea_';

  /// Borra reportes temporales de más de 10 minutos (no se borran al instante porque
  /// la app que recibe el archivo, por ejemplo Gmail, puede leerlo unos segundos después).
  static Future<void> limpiarViejos() async {
    try {
      final dir = await getTemporaryDirectory();
      final limite = DateTime.now().subtract(const Duration(minutes: 10));
      for (final f in dir.listSync().whereType<File>()) {
        final nombre = f.uri.pathSegments.last;
        if (nombre.startsWith(_prefijo) && f.lastModifiedSync().isBefore(limite)) {
          f.deleteSync();
        }
      }
    } catch (_) {}
  }

  static String _fecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _delta(int actual, int anterior) {
    final d = actual - anterior;
    if (d == 0) return 'igual que la semana anterior';
    return d > 0 ? '$d más que la semana anterior' : '${-d} menos que la semana anterior';
  }

  /// Genera el PDF, abre la hoja de compartir y devuelve true si se generó.
  static Future<bool> generarYCompartir() async {
    await limpiarViejos();
    final nino = await AuthService().getPerfilNino();
    final (act, ant) = await ResumenSeguimiento.semanaActualYAnterior();
    final notas = await RegistroUsoService().notas(limite: 10);
    final nombre = (nino?.nombre.isNotEmpty ?? false) ? nino!.nombre : 'el niño o la niña';
    final hastaIncl = act.hasta.subtract(const Duration(days: 1));

    final titulo = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF3D6D7E));
    final sub = pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold);
    const normal = pw.TextStyle(fontSize: 10.5);
    final gris = pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF6B6B66));

    pw.Widget fila(String a, String b) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Text(a, style: normal)),
            pw.Text(b, style: normal.copyWith(fontWeight: pw.FontWeight.bold)),
          ]),
        );

    final doc = pw.Document(title: 'Reporte de seguimiento - Brillantea', author: 'Brillantea');
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (ctx) => [
        pw.Text('Reporte de seguimiento', style: titulo),
        pw.SizedBox(height: 4),
        pw.Text('Brillantea - generado en el dispositivo el ${_fecha(DateTime.now())}', style: gris),
        pw.SizedBox(height: 14),
        fila('Niño o niña (nombre o apodo)', nombre),
        if (nino != null) fila('Edad', '${nino.edad} años'),
        fila('Periodo', '${_fecha(act.desde)} al ${_fecha(hastaIncl)} (últimos 7 días)'),
        pw.SizedBox(height: 14),
        pw.Text('Rutinas', style: sub),
        pw.Divider(thickness: 0.6),
        fila('Rutinas iniciadas', '${act.rutinasIniciadas}'),
        fila('Rutinas completadas', '${act.rutinasCompletadas}'),
        fila('Comparación', _delta(act.rutinasCompletadas, ant.rutinasCompletadas)),
        for (final e in act.completadasPorRutina.entries) fila('   ${e.key}', '${e.value} veces'),
        pw.SizedBox(height: 12),
        pw.Text('Comunicación', style: sub),
        pw.Divider(thickness: 0.6),
        fila('Peticiones (Pedir algo, Armar frase, cámara)', '${act.peticiones}'),
        fila('Comparación', _delta(act.peticiones, ant.peticiones)),
        fila('Respuestas Sí / No', '${act.respuestas}'),
        if (act.masUsados.isNotEmpty) pw.SizedBox(height: 4),
        if (act.masUsados.isNotEmpty) pw.Text('Lo más usado:', style: normal),
        for (final e in act.masUsados) fila('   "${e.key}"', '${e.value} veces'),
        pw.SizedBox(height: 12),
        pw.Text('Emociones', style: sub),
        pw.Divider(thickness: 0.6),
        if (act.emociones.isEmpty) pw.Text('No se registraron emociones en el periodo.', style: normal),
        for (final e in act.emociones.entries) fila(e.key, '${e.value} veces'),
        fila('Momentos difíciles (triste, enojado, asustado, nervioso)', '${act.momentosDificiles}'),
        fila('Comparación', _delta(act.momentosDificiles, ant.momentosDificiles)),
        pw.SizedBox(height: 12),
        pw.Text('Cámara', style: sub),
        pw.Divider(thickness: 0.6),
        fila('Objetos reconocidos que el niño o la niña tocó', '${act.objetosTocados}'),
        pw.SizedBox(height: 12),
        pw.Text('Notas para el especialista', style: sub),
        pw.Divider(thickness: 0.6),
        if (notas.isEmpty) pw.Text('Sin notas registradas.', style: normal),
        for (final n in notas)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text('${_fecha(n.fecha)}: ${n.texto}', style: normal),
          ),
        pw.SizedBox(height: 18),
        pw.Text(
          'Este reporte se generó sin conexión a internet. No contiene imágenes ni datos de salud; '
          'solo el nombre o apodo, la edad y conteos de uso de la aplicación. '
          'Es un apoyo para el seguimiento y no reemplaza la evaluación de un profesional.',
          style: gris,
        ),
      ],
    ));

    final dir = await getTemporaryDirectory();
    final ahora = DateTime.now();
    final archivo = File('${dir.path}/$_prefijo${ahora.year}${ahora.month.toString().padLeft(2, '0')}'
        '${ahora.day.toString().padLeft(2, '0')}_${ahora.millisecondsSinceEpoch}.pdf');
    await archivo.writeAsBytes(await doc.save());
    await SharePlus.instance.share(ShareParams(
      files: [XFile(archivo.path, mimeType: 'application/pdf')],
      subject: 'Reporte de seguimiento - $nombre',
    ));
    return true;
  }
}
