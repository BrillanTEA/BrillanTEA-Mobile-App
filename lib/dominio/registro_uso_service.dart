import 'package:sqflite/sqflite.dart';

import '../datos/base_datos.dart';

/// Un evento de uso guardado en el dispositivo (nunca se envía a internet).
class EventoUso {
  final String tipo; // ver RegistroUsoService.tipos
  final String clave; // id estable: 'com_comer', 'tranquilo', '3' (id de rutina), 'zapatos'...
  final String etiqueta; // texto legible: 'Quiero comer', 'Tranquilo', 'Lavado de manos'
  final DateTime fecha;

  const EventoUso(this.tipo, this.clave, this.etiqueta, this.fecha);
}

class NotaEspecialista {
  final String texto;
  final DateTime fecha;
  const NotaEspecialista(this.texto, this.fecha);
}

/// Registro de Uso: guarda en SQLite cada interacción relevante del niño,
/// con fecha, para el Seguimiento y el reporte PDF. Solo datos mínimos: tipo, qué se tocó y cuándo.
///
/// Tablas (en catalogo.db, ver base_datos.dart):
///   registro_uso(id, tipo, clave, etiqueta, ts)   ts = milisegundos desde 1970
///   nota_especialista(id, texto, ts)              notas del adulto para el especialista
class RegistroUsoService {
  static final RegistroUsoService _instance = RegistroUsoService._internal();
  factory RegistroUsoService() => _instance;
  RegistroUsoService._internal();

  static const String peticion = 'peticion'; // Pedir algo, Armar frase, pedir desde la cámara
  static const String respuesta = 'respuesta'; // Sí / No
  static const String emocion = 'emocion';
  static const String rutinaInicio = 'rutina_inicio';
  static const String rutinaPaso = 'rutina_paso';
  static const String rutinaFin = 'rutina_fin';
  static const String pictograma = 'pictograma'; // Vocabulario y Favoritos
  static const String objeto = 'objeto'; // objeto detectado que el niño tocó en la cámara
  static const String calma = 'calma'; // Módulo Calma: ejercicio usado y cómo se sintió después

  /// Emociones que cuentan como "momentos difíciles" en el seguimiento.
  static const Set<String> emocionesDificiles = {'triste', 'enojado', 'asustado', 'nervioso'};

  Future<Database> get _base => BaseDatos().db;

  /// Guarda un evento. Nunca lanza error: si algo falla, la app sigue funcionando igual.
  Future<void> registrar(String tipo, String clave, {String? etiqueta}) async {
    try {
      final db = await _base;
      await db.insert('registro_uso', {
        'tipo': tipo,
        'clave': clave,
        'etiqueta': etiqueta ?? clave,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  /// Eventos entre [desde] (incluido) y [hasta] (excluido).
  Future<List<EventoUso>> eventos(DateTime desde, DateTime hasta) async {
    try {
      final db = await _base;
      final filas = await db.query(
        'registro_uso',
        where: 'ts >= ? AND ts < ?',
        whereArgs: [desde.millisecondsSinceEpoch, hasta.millisecondsSinceEpoch],
        orderBy: 'ts ASC',
      );
      return [
        for (final f in filas)
          EventoUso(
            f['tipo'] as String,
            f['clave'] as String,
            f['etiqueta'] as String,
            DateTime.fromMillisecondsSinceEpoch(f['ts'] as int),
          ),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> agregarNota(String texto) async {
    try {
      final db = await _base;
      await db.insert('nota_especialista', {'texto': texto, 'ts': DateTime.now().millisecondsSinceEpoch});
    } catch (_) {}
  }

  Future<List<NotaEspecialista>> notas({int limite = 20}) async {
    try {
      final db = await _base;
      final filas = await db.query('nota_especialista', orderBy: 'ts DESC', limit: limite);
      return [
        for (final f in filas)
          NotaEspecialista(f['texto'] as String, DateTime.fromMillisecondsSinceEpoch(f['ts'] as int)),
      ];
    } catch (_) {
      return [];
    }
  }

  /// Borra la base de datos completa (Área de padres → borrar los datos).
  Future<void> borrarTodo() => BaseDatos().borrarTodo();
}

/// Resumen de un periodo para la pantalla de Seguimiento y el reporte.
class ResumenSeguimiento {
  final DateTime desde, hasta;
  final int rutinasIniciadas; // pares (rutina, día) en que se empezó una rutina
  final int rutinasCompletadas; // pares (rutina, día) en que se terminó
  final Map<String, int> completadasPorRutina; // nombre de rutina -> veces completada
  final int peticiones; // intenciones comunicativas (Pedir algo, Armar frase, cámara)
  final int respuestas; // Sí / No
  final Map<String, int> emociones; // nombre de emoción -> veces
  final String? emocionFrecuente;
  final int emocionFrecuenteVeces;
  final int momentosDificiles;
  final List<MapEntry<String, int>> masUsados; // frases o pictogramas más usados
  final int objetosTocados;

  const ResumenSeguimiento({
    required this.desde,
    required this.hasta,
    required this.rutinasIniciadas,
    required this.rutinasCompletadas,
    required this.completadasPorRutina,
    required this.peticiones,
    required this.respuestas,
    required this.emociones,
    required this.emocionFrecuente,
    required this.emocionFrecuenteVeces,
    required this.momentosDificiles,
    required this.masUsados,
    required this.objetosTocados,
  });

  bool get vacio =>
      rutinasIniciadas == 0 && peticiones == 0 && respuestas == 0 && emociones.isEmpty && objetosTocados == 0;

  static String _dia(DateTime d) => '${d.year}-${d.month}-${d.day}';

  factory ResumenSeguimiento.desde(List<EventoUso> ev, DateTime desde, DateTime hasta) {
    final iniciadas = <String>{}, completadas = <String>{};
    final porRutina = <String, int>{};
    final emociones = <String, int>{};
    final usos = <String, int>{};
    var peticiones = 0, respuestas = 0, dificiles = 0, objetos = 0;
    for (final e in ev) {
      final par = '${e.clave}|${_dia(e.fecha)}';
      switch (e.tipo) {
        case RegistroUsoService.rutinaInicio:
        case RegistroUsoService.rutinaPaso:
          iniciadas.add(par);
        case RegistroUsoService.rutinaFin:
          iniciadas.add(par);
          if (completadas.add(par)) porRutina[e.etiqueta] = (porRutina[e.etiqueta] ?? 0) + 1;
        case RegistroUsoService.peticion:
          peticiones++;
          usos[e.etiqueta] = (usos[e.etiqueta] ?? 0) + 1;
        case RegistroUsoService.respuesta:
          respuestas++;
          usos[e.etiqueta] = (usos[e.etiqueta] ?? 0) + 1;
        case RegistroUsoService.pictograma:
          usos[e.etiqueta] = (usos[e.etiqueta] ?? 0) + 1;
        case RegistroUsoService.emocion:
          emociones[e.etiqueta] = (emociones[e.etiqueta] ?? 0) + 1;
          if (RegistroUsoService.emocionesDificiles.contains(e.clave)) dificiles++;
        case RegistroUsoService.objeto:
          objetos++;
      }
    }
    String? frecuente;
    var veces = 0;
    emociones.forEach((k, v) {
      if (v > veces) {
        frecuente = k;
        veces = v;
      }
    });
    final top = usos.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return ResumenSeguimiento(
      desde: desde,
      hasta: hasta,
      rutinasIniciadas: iniciadas.length,
      rutinasCompletadas: completadas.length,
      completadasPorRutina: porRutina,
      peticiones: peticiones,
      respuestas: respuestas,
      emociones: emociones,
      emocionFrecuente: frecuente,
      emocionFrecuenteVeces: veces,
      momentosDificiles: dificiles,
      masUsados: top.take(5).toList(),
      objetosTocados: objetos,
    );
  }

  /// Últimos 7 días (incluido hoy) y los 7 anteriores.
  static Future<(ResumenSeguimiento, ResumenSeguimiento)> semanaActualYAnterior() async {
    final ahora = DateTime.now();
    final finHoy = DateTime(ahora.year, ahora.month, ahora.day).add(const Duration(days: 1));
    final ini = finHoy.subtract(const Duration(days: 7));
    final iniAnt = ini.subtract(const Duration(days: 7));
    final reg = RegistroUsoService();
    final actual = ResumenSeguimiento.desde(await reg.eventos(ini, finHoy), ini, finHoy);
    final anterior = ResumenSeguimiento.desde(await reg.eventos(iniAnt, ini), iniAnt, ini);
    return (actual, anterior);
  }
}
