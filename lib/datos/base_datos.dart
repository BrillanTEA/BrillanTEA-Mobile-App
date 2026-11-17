import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Repositorio Local (capa de datos): único punto de acceso a la base SQLite catalogo.db.
///
/// Tablas:
///   Catálogo (solo lectura, se carga desde assets/catalogo.json en el primer uso
///   y cada vez que cambia ese archivo): pictograma, rutina, objeto, cierre_rutina.
///   Perfiles: perfil_adulto, perfil_nino (un registro cada una).
///   Configuración: ajuste (registro único), preferencia_accesibilidad, configuracion_rutina, favorito,
///                  configuracion_premios (v3; período en v7).
///   Seguimiento: progreso_rutina, registro_uso, nota_especialista.
///
/// Integridad referencial (v6): FOREIGN KEY sin ON DELETE CASCADE en rutina y objeto → pictograma,
/// objeto, cierre_rutina, configuracion_rutina y progreso_rutina → rutina. PRAGMA foreign_keys se
/// activa en onConfigure. registro_uso.clave es polimórfica (objeto o rutina según tipo) y no lleva FK.
///
/// Si la app tenía datos en SharedPreferences (versiones anteriores), se copian una sola vez
/// a SQLite al abrir la base y luego se borran de SharedPreferences.
class BaseDatos {
  static final BaseDatos _instance = BaseDatos._internal();
  factory BaseDatos() => _instance;
  BaseDatos._internal();

  static const String archivo = 'catalogo.db'; // nombre de la base de datos local
  static const int _version = 8; // 1 = solo registro de uso y notas; 2 = todo en SQLite; 3 = premios; 4 = tutoriales; 5 = una sola clase del modelo (YOLO26s, 35 clases); 6 = claves foráneas (FOREIGN KEY); 7 = período de los premios; 8 = versión aceptada de los documentos
  Future<Database>? _db;

  /// Tabla OBJETO (v5): id_modelo es la clase que entrega YOLO26s (0 a 34, mismo orden que
  /// assets/models/yolo26_35_020_fp32.txt). Reemplaza coco_clase, clase_propia y
  /// requiere_finetuning del sistema doble anterior.
  static const String _sqlObjeto =
      'CREATE TABLE objeto (clave TEXT PRIMARY KEY, tipo TEXT NOT NULL, nombre TEXT NOT NULL, '
      'termino_arasaac TEXT, frase_apoyo TEXT, frase_fuera_rutina TEXT, frase_peticion TEXT, '
      'id_modelo INTEGER, categoria TEXT, archivo_pictograma TEXT REFERENCES pictograma(archivo), '
      'rutina_id INTEGER REFERENCES rutina(id), paso INTEGER, '
      'aviso_anticipacion TEXT, orden INTEGER NOT NULL DEFAULT 0)';

  Future<Database> get db => _db ??= _abrir();

  Future<String> get _ruta async => '${await getDatabasesPath()}/$archivo';

  Future<Database> _abrir() async {
    try {
      final db = await openDatabase(
        await _ruta,
        version: _version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => _crearTablas(db, desde: 0),
        onUpgrade: (db, viejo, nuevo) => _crearTablas(db, desde: viejo),
      );
      try {
        await _cargarCatalogo(db);
      } catch (_) {} // si falla, CatalogoService usa el JSON directamente
      try {
        await _migrarPreferencias(db);
      } catch (_) {}
      return db;
    } catch (e) {
      _db = null; // permite reintentar en la próxima llamada
      rethrow;
    }
  }

  /// Borra la base completa (Configuración → borrar los datos de la aplicación).
  Future<void> borrarTodo() async {
    try {
      if (_db != null) {
        final db = await _db!;
        await db.close();
      }
    } catch (_) {}
    _db = null;
    try {
      await deleteDatabase(await _ruta);
    } catch (_) {}
  }

  static Future<void> _crearTablas(Database db, {required int desde}) async {
    final b = db.batch();
    if (desde == 1) {
      // versión 1: el registro de uso usaba los nombres eventos y notas
      b.execute('ALTER TABLE eventos RENAME TO registro_uso');
      b.execute('ALTER TABLE notas RENAME TO nota_especialista');
    }
    if (desde < 1) {
      b.execute('CREATE TABLE registro_uso (id INTEGER PRIMARY KEY AUTOINCREMENT, tipo TEXT NOT NULL, '
          'clave TEXT NOT NULL, etiqueta TEXT NOT NULL, ts INTEGER NOT NULL)');
      b.execute('CREATE INDEX idx_registro_uso_ts ON registro_uso(ts)');
      b.execute('CREATE TABLE nota_especialista (id INTEGER PRIMARY KEY AUTOINCREMENT, texto TEXT NOT NULL, '
          'ts INTEGER NOT NULL)');
    }
    if (desde < 2) {
      // Catálogo
      b.execute('CREATE TABLE pictograma (archivo TEXT PRIMARY KEY, termino_arasaac TEXT)');
      b.execute('CREATE TABLE rutina (id INTEGER PRIMARY KEY, nombre TEXT NOT NULL, ambito TEXT, '
          'termino_arasaac TEXT, archivo_pictograma TEXT REFERENCES pictograma(archivo), orden INTEGER NOT NULL DEFAULT 0)');
      b.execute(_sqlObjeto);
      b.execute('CREATE TABLE cierre_rutina (rutina_id INTEGER PRIMARY KEY REFERENCES rutina(id), mensaje TEXT, opcion_a TEXT, '
          'opcion_b TEXT, criterio TEXT)');
      // Perfiles
      b.execute('CREATE TABLE perfil_adulto (id INTEGER PRIMARY KEY CHECK (id = 1), '
          "nombres TEXT NOT NULL DEFAULT '', apellido_paterno TEXT NOT NULL DEFAULT '', "
          "apellido_materno TEXT NOT NULL DEFAULT '', dia_nacimiento TEXT NOT NULL DEFAULT '', "
          "mes_nacimiento TEXT NOT NULL DEFAULT '', anio_nacimiento TEXT NOT NULL DEFAULT '', "
          "ciudad_nacimiento TEXT NOT NULL DEFAULT '', edad TEXT NOT NULL DEFAULT '', "
          "sexo TEXT NOT NULL DEFAULT '', parentesco TEXT NOT NULL DEFAULT '')");
      b.execute('CREATE TABLE perfil_nino (id INTEGER PRIMARY KEY CHECK (id = 1), nombre TEXT NOT NULL, '
          'edad INTEGER NOT NULL, avatar TEXT NOT NULL)');
      // Configuración
      b.execute('CREATE TABLE ajuste (id INTEGER PRIMARY KEY CHECK (id = 1), '
          'configurada INTEGER NOT NULL DEFAULT 0, acuerdo_privacidad INTEGER NOT NULL DEFAULT 0, '
          'acuerdo_fecha TEXT, pin_hash TEXT, pin_salt TEXT, intentos_pin INTEGER NOT NULL DEFAULT 0, '
          'intentos_recuperacion INTEGER NOT NULL DEFAULT 0, bloqueado_hasta INTEGER, '
          'pantalla_fijada INTEGER NOT NULL DEFAULT 0, catalogo_hash TEXT, '
          'preferencias_migradas INTEGER NOT NULL DEFAULT 0)');
      b.insert('ajuste', {'id': 1});
      b.execute('CREATE TABLE preferencia_accesibilidad (id INTEGER PRIMARY KEY CHECK (id = 1), '
          'tamano_texto INTEGER NOT NULL DEFAULT 1, sonidos INTEGER NOT NULL DEFAULT 0, '
          'vibracion INTEGER NOT NULL DEFAULT 1, leer_voz_alta INTEGER NOT NULL DEFAULT 0, '
          'tutorial_camara INTEGER NOT NULL DEFAULT 1)');
      b.insert('preferencia_accesibilidad', {'id': 1});
      b.execute('CREATE TABLE configuracion_rutina (rutina_id INTEGER PRIMARY KEY REFERENCES rutina(id), activa INTEGER NOT NULL)');
      b.execute('CREATE TABLE favorito (id TEXT PRIMARY KEY, nombre TEXT NOT NULL, modulo TEXT NOT NULL, '
          'color INTEGER NOT NULL, asset_path TEXT, simbolo_texto TEXT, silabas TEXT, frase_voz TEXT NOT NULL, '
          'contador_uso INTEGER NOT NULL DEFAULT 0, creado_ts INTEGER NOT NULL)');
      // Seguimiento
      b.execute('CREATE TABLE progreso_rutina (rutina_id INTEGER NOT NULL, fecha TEXT NOT NULL, '
          'paso_actual INTEGER NOT NULL, completada INTEGER NOT NULL, PRIMARY KEY (rutina_id, fecha), '
          'FOREIGN KEY (rutina_id) REFERENCES rutina(id))');
    }
    if (desde < 3) {
      // Las medallas no se guardan aparte: 1 medalla = 1 rutina completada en un día (progreso_rutina).
      b.execute('CREATE TABLE configuracion_premios (id INTEGER PRIMARY KEY CHECK (id = 1), '
          'activado INTEGER NOT NULL DEFAULT 1, meta_semanal INTEGER NOT NULL DEFAULT 20)');
      b.insert('configuracion_premios', {'id': 1});
    }
    if (desde < 4) {
      // Módulos cuyo tutorial ya vio el adulto.
      b.execute('CREATE TABLE tutorial_visto (clave TEXT PRIMARY KEY, ts INTEGER NOT NULL)');
    }
    if (desde >= 2 && desde < 5) {
      // v5: la tabla objeto es solo catálogo (se recarga desde catalogo.json), así que se rehace
      // con la columna id_modelo y se fuerza la recarga del catálogo.
      b.execute('DROP TABLE IF EXISTS objeto');
      b.execute(_sqlObjeto);
      b.execute('UPDATE ajuste SET catalogo_hash = NULL WHERE id = 1');
    }
    if (desde >= 2 && desde < 6) {
      // v6: SQLite no permite agregar FOREIGN KEY con ALTER TABLE, así que cada tabla se rehace
      // (crear nueva, copiar, borrar la vieja y renombrar), primero los padres y luego los hijos.
      // Las filas huérfanas no se copian. Se conservan el progreso y la configuración del niño.
      b.execute('PRAGMA defer_foreign_keys = ON');
      void rehacer(String tabla, String sqlNueva, String columnas, [String filtro = '']) {
        b.execute(sqlNueva.replaceFirst('CREATE TABLE $tabla ', 'CREATE TABLE ${tabla}_v6 '));
        b.execute('INSERT INTO ${tabla}_v6 ($columnas) SELECT $columnas FROM $tabla $filtro');
        b.execute('DROP TABLE $tabla');
        b.execute('ALTER TABLE ${tabla}_v6 RENAME TO $tabla');
      }
      rehacer('pictograma', 'CREATE TABLE pictograma (archivo TEXT PRIMARY KEY, termino_arasaac TEXT)',
          'archivo, termino_arasaac');
      rehacer(
          'rutina',
          'CREATE TABLE rutina (id INTEGER PRIMARY KEY, nombre TEXT NOT NULL, ambito TEXT, termino_arasaac TEXT, '
              'archivo_pictograma TEXT REFERENCES pictograma(archivo), orden INTEGER NOT NULL DEFAULT 0)',
          'id, nombre, ambito, termino_arasaac, archivo_pictograma, orden',
          'WHERE archivo_pictograma IS NULL OR archivo_pictograma IN (SELECT archivo FROM pictograma)');
      rehacer(
          'objeto',
          _sqlObjeto,
          'clave, tipo, nombre, termino_arasaac, frase_apoyo, frase_fuera_rutina, frase_peticion, id_modelo, '
              'categoria, archivo_pictograma, rutina_id, paso, aviso_anticipacion, orden',
          'WHERE (rutina_id IS NULL OR rutina_id IN (SELECT id FROM rutina)) '
              'AND (archivo_pictograma IS NULL OR archivo_pictograma IN (SELECT archivo FROM pictograma))');
      const soloRutinasExistentes = 'WHERE rutina_id IN (SELECT id FROM rutina)';
      rehacer(
          'cierre_rutina',
          'CREATE TABLE cierre_rutina (rutina_id INTEGER PRIMARY KEY REFERENCES rutina(id), mensaje TEXT, '
              'opcion_a TEXT, opcion_b TEXT, criterio TEXT)',
          'rutina_id, mensaje, opcion_a, opcion_b, criterio',
          soloRutinasExistentes);
      rehacer(
          'configuracion_rutina',
          'CREATE TABLE configuracion_rutina (rutina_id INTEGER PRIMARY KEY REFERENCES rutina(id), '
              'activa INTEGER NOT NULL)',
          'rutina_id, activa',
          soloRutinasExistentes);
      rehacer(
          'progreso_rutina',
          'CREATE TABLE progreso_rutina (rutina_id INTEGER NOT NULL, fecha TEXT NOT NULL, '
              'paso_actual INTEGER NOT NULL, completada INTEGER NOT NULL, PRIMARY KEY (rutina_id, fecha), '
              'FOREIGN KEY (rutina_id) REFERENCES rutina(id))',
          'rutina_id, fecha, paso_actual, completada',
          soloRutinasExistentes);
    }
    if (desde < 7) {
      // v7: la meta de premios puede ser diaria, semanal o mensual. meta_semanal guarda la meta
      // del período elegido (se conserva el nombre para no rehacer la tabla).
      b.execute("ALTER TABLE configuracion_premios ADD COLUMN periodo TEXT NOT NULL DEFAULT 'semanal'");
    }
    if (desde < 8) {
      // v8: junto con la fecha de aceptación se guarda la versión de los Términos y la Política
      // (se muestra en Área de padres → Privacidad y datos).
      b.execute('ALTER TABLE ajuste ADD COLUMN acuerdo_version TEXT');
    }
    await b.commit(noResult: true);
  }

  /// Script de carga inicial: copia assets/catalogo.json a las tablas del catálogo.
  /// Se vuelve a cargar solo si el archivo cambió (se compara su huella SHA-1).
  static Future<void> _cargarCatalogo(Database db) async {
    final texto = await rootBundle.loadString('assets/catalogo.json');
    final huella = sha1.convert(utf8.encode(texto)).toString();
    final fila = await db.query('ajuste', columns: ['catalogo_hash'], where: 'id = 1');
    if (fila.isNotEmpty && fila.first['catalogo_hash'] == huella) return;
    final data = jsonDecode(texto) as Map<String, dynamic>;

    await db.transaction((txn) async {
      final b = txn.batch();
      // Las FK se revisan al confirmar la transacción: así se puede borrar y volver a insertar el
      // catálogo sin perder el progreso ni la configuración de las rutinas (no hay ON DELETE CASCADE).
      b.execute('PRAGMA defer_foreign_keys = ON');
      for (final t in const ['cierre_rutina', 'objeto', 'rutina', 'pictograma']) {
        b.delete(t);
      }
      final pictos = <String, Object?>{};
      var orden = 0;
      for (final r in (data['rutinas'] as List? ?? const [])) {
        final m = r as Map<String, dynamic>;
        final archivo = m['archivo_pictograma'] as String? ?? 'rutina_${m['id']}_8975.png';
        pictos[archivo] = m['termino_arasaac'];
        b.insert('rutina', {
          'id': m['id'],
          'nombre': m['nombre'],
          'ambito': m['ambito'],
          'termino_arasaac': m['termino_arasaac'],
          'archivo_pictograma': archivo,
          'orden': orden++,
        });
      }
      orden = 0;
      for (final o in (data['objetos'] as List? ?? const [])) {
        final m = o as Map<String, dynamic>;
        final archivo = m['archivo_pictograma'] as String? ?? '${m['clave']}.png';
        pictos[archivo] = m['termino_arasaac'];
        b.insert(
          'objeto',
          {
            'clave': m['clave'],
            'tipo': 'objeto',
            'nombre': m['nombre'],
            'termino_arasaac': m['termino_arasaac'],
            'frase_apoyo': m['frase_apoyo'],
            'frase_fuera_rutina': m['frase_fuera_rutina'],
            'frase_peticion': m['frase_peticion'],
            'id_modelo': m['id_modelo'],
            'categoria': m['categoria'],
            'archivo_pictograma': archivo,
            'rutina_id': m['rutina_id'],
            'paso': m['paso'],
            'aviso_anticipacion': m['aviso_anticipacion'],
            'orden': orden++,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final e in (data['extra'] as List? ?? const [])) {
        final m = e as Map<String, dynamic>;
        final archivo = m['archivo_pictograma'] as String? ?? 'colegio_32446.png';
        pictos[archivo] = m['termino_arasaac'];
        b.insert(
          'objeto',
          {
            'clave': m['clave'],
            'tipo': 'extra',
            'nombre': m['nombre'],
            'termino_arasaac': m['termino_arasaac'],
            'categoria': 'Contexto',
            'archivo_pictograma': archivo,
            'orden': orden++,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final c in (data['cierres'] as List? ?? const [])) {
        final m = c as Map<String, dynamic>;
        b.insert(
          'cierre_rutina',
          {
            'rutina_id': m['rutina_id'],
            'mensaje': m['mensaje'],
            'opcion_a': m['opcion_a'],
            'opcion_b': m['opcion_b'],
            'criterio': m['criterio'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      pictos.forEach((archivo, termino) {
        b.insert('pictograma', {'archivo': archivo, 'termino_arasaac': termino},
            conflictAlgorithm: ConflictAlgorithm.replace);
      });
      // Si una rutina salió del catálogo, se borra su progreso y su configuración (filas huérfanas).
      b.execute('DELETE FROM progreso_rutina WHERE rutina_id NOT IN (SELECT id FROM rutina)');
      b.execute('DELETE FROM configuracion_rutina WHERE rutina_id NOT IN (SELECT id FROM rutina)');
      b.update('ajuste', {'catalogo_hash': huella}, where: 'id = 1');
      await b.commit(noResult: true);
    });
  }

  /// Copia una sola vez los datos que versiones anteriores guardaban en SharedPreferences.
  static Future<void> _migrarPreferencias(Database db) async {
    final f = await db.query('ajuste', columns: ['preferencias_migradas'], where: 'id = 1');
    if (f.isNotEmpty && f.first['preferencias_migradas'] == 1) return;

    final sp = await SharedPreferences.getInstance();
    T? leer<T>(String k) {
      final v = sp.get(k);
      return v is T ? v : null;
    }

    Map<String, dynamic>? json(String k) {
      final s = leer<String>(k);
      if (s == null || s.isEmpty) return null;
      try {
        final v = jsonDecode(s);
        return v is Map<String, dynamic> ? v : null;
      } catch (_) {
        return null;
      }
    }

    int b01(bool? v, int porDefecto) => v == null ? porDefecto : (v ? 1 : 0);

    await db.transaction((txn) async {
      final b = txn.batch();
      // Seguridad y ajustes
      b.update(
        'ajuste',
        {
          'configurada': b01(leer<bool>('auth_configurada'), 0),
          'acuerdo_privacidad': b01(leer<bool>('auth_acuerdo_privacidad_aceptado'), 0),
          'acuerdo_fecha': leer<String>('auth_acuerdo_privacidad_fecha'),
          'pin_hash': leer<String>('auth_pin_hash'),
          'pin_salt': leer<String>('auth_pin_salt'),
          'intentos_pin': leer<int>('auth_failed_attempts') ?? 0,
          'intentos_recuperacion': leer<int>('auth_recovery_failed_attempts') ?? 0,
          'bloqueado_hasta': leer<int>('auth_locked_until'),
          'pantalla_fijada': b01(leer<bool>('acc_bloqueo_activo'), 0),
          'preferencias_migradas': 1,
        },
        where: 'id = 1',
      );
      // Perfiles
      final a = json('auth_perfil_adulto');
      if (a != null) {
        b.insert(
          'perfil_adulto',
          {
            'id': 1,
            'nombres': '${a['nombres'] ?? a['nombre'] ?? ''}',
            'apellido_paterno': '${a['apellidoPaterno'] ?? ''}',
            'apellido_materno': '${a['apellidoMaterno'] ?? ''}',
            'dia_nacimiento': '${a['diaNacimiento'] ?? ''}',
            'mes_nacimiento': '${a['mesNacimiento'] ?? 'Abril'}',
            'anio_nacimiento': '${a['anioNacimiento'] ?? ''}',
            'ciudad_nacimiento': '${a['ciudadNacimiento'] ?? ''}',
            'edad': '${a['edad'] ?? ''}',
            'sexo': '${a['sexo'] ?? 'Femenino'}',
            'parentesco': '${a['parentesco'] ?? 'Madre'}',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      final n = json('auth_perfil_nino');
      if (n != null) {
        b.insert(
          'perfil_nino',
          {
            'id': 1,
            'nombre': '${n['nombre'] ?? ''}',
            'edad': n['edad'] is int ? n['edad'] : (int.tryParse('${n['edad']}') ?? 9),
            'avatar': '${n['avatar'] ?? 'nino'}',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      // Accesibilidad
      b.update(
        'preferencia_accesibilidad',
        {
          'tamano_texto': leer<int>('acc_tamano_texto_idx') ?? 1,
          'sonidos': b01(leer<bool>('acc_sonidos_app'), 0),
          'vibracion': b01(leer<bool>('acc_vibracion'), 1),
          'leer_voz_alta': b01(leer<bool>('acc_leer_voz_alta'), 0),
          'tutorial_camara': b01(leer<bool>('acc_tutorial_camara'), 1),
        },
        where: 'id = 1',
      );
      // Rutinas desactivadas
      for (final s in leer<List>('rutinas_desactivadas_ids_v1') ?? const []) {
        final id = int.tryParse('$s');
        if (id != null) {
          b.insert('configuracion_rutina', {'rutina_id': id, 'activa': 0},
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      // Progreso diario de rutinas (una clave por día: rutinas_progreso_AAAA-MM-DD)
      for (final k in sp.getKeys().where((k) => k.startsWith('rutinas_progreso_'))) {
        final fecha = k.substring('rutinas_progreso_'.length);
        final mapa = json(k) ?? const <String, dynamic>{};
        mapa.forEach((idTxt, v) {
          final id = int.tryParse(idTxt);
          if (id != null && v is Map) {
            b.insert(
              'progreso_rutina',
              {
                'rutina_id': id,
                'fecha': fecha,
                'paso_actual': v['pasoActual'] is int ? v['pasoActual'] : 0,
                'completada': v['completada'] == true ? 1 : 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
      }
      // Favoritos
      final favTxt = leer<String>('brillantea_favoritos_v2');
      if (favTxt != null && favTxt.isNotEmpty) {
        try {
          final lista = jsonDecode(favTxt) as List;
          var ts = DateTime.now().millisecondsSinceEpoch;
          for (final item in lista) {
            final m = item as Map<String, dynamic>;
            b.insert(
              'favorito',
              {
                'id': '${m['id']}',
                'nombre': '${m['nombre']}',
                'modulo': '${m['modulo'] ?? 'Vocabulario'}',
                'color': m['colorModuloValue'] is int ? m['colorModuloValue'] : 0xFF3D6D7E,
                'asset_path': m['assetPath'],
                'simbolo_texto': m['simboloTexto'],
                'silabas': m['silabas'],
                'frase_voz': '${m['fraseVoz'] ?? m['nombre']}',
                'contador_uso': m['contadorUso'] is int ? m['contadorUso'] : 0,
                'creado_ts': ts++,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        } catch (_) {}
      }
      await b.commit(noResult: true);
    });

    // Ya está todo en SQLite: se borran las copias viejas de SharedPreferences.
    for (final k in sp.getKeys().toList()) {
      if (k.startsWith('auth_') ||
          k.startsWith('acc_') ||
          k.startsWith('rutinas_') ||
          k.startsWith('brillantea_favoritos')) {
        await sp.remove(k);
      }
    }
  }
}
