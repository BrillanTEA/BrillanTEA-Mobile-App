import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../datos/base_datos.dart';

class FavoritoItem {
  final String id;
  final String nombre;
  final String modulo; // 'Comunicación', 'Vocabulario', 'Emociones', 'Rutinas', 'Situaciones'
  final int colorModuloValue; // Color value as int
  final String? assetPath;
  final String? simboloTexto;
  final String? silabas;
  final String fraseVoz;
  int contadorUso;

  FavoritoItem({
    required this.id,
    required this.nombre,
    required this.modulo,
    required this.colorModuloValue,
    this.assetPath,
    this.simboloTexto,
    this.silabas,
    required this.fraseVoz,
    this.contadorUso = 0,
  });

  Color get colorModulo => Color(colorModuloValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'modulo': modulo,
        'colorModuloValue': colorModuloValue,
        'assetPath': assetPath,
        'simboloTexto': simboloTexto,
        'silabas': silabas,
        'fraseVoz': fraseVoz,
        'contadorUso': contadorUso,
      };

  /// Fila de la tabla favorito (SQLite).
  Map<String, Object?> toFila(int creadoTs) => {
        'id': id,
        'nombre': nombre,
        'modulo': modulo,
        'color': colorModuloValue,
        'asset_path': assetPath,
        'simbolo_texto': simboloTexto,
        'silabas': silabas,
        'frase_voz': fraseVoz,
        'contador_uso': contadorUso,
        'creado_ts': creadoTs,
      };

  factory FavoritoItem.fromFila(Map<String, Object?> f) => FavoritoItem(
        id: f['id'] as String,
        nombre: f['nombre'] as String,
        modulo: f['modulo'] as String? ?? 'Vocabulario',
        colorModuloValue: f['color'] as int? ?? 0xFF3D6D7E,
        assetPath: f['asset_path'] as String?,
        simboloTexto: f['simbolo_texto'] as String?,
        silabas: f['silabas'] as String?,
        fraseVoz: f['frase_voz'] as String? ?? f['nombre'] as String,
        contadorUso: f['contador_uso'] as int? ?? 0,
      );

  factory FavoritoItem.fromJson(Map<String, dynamic> json) => FavoritoItem(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        modulo: json['modulo'] as String? ?? 'Vocabulario',
        colorModuloValue: json['colorModuloValue'] as int? ?? 0xFF3D6D7E,
        assetPath: json['assetPath'] as String?,
        simboloTexto: json['simboloTexto'] as String?,
        silabas: json['silabas'] as String?,
        fraseVoz: json['fraseVoz'] as String? ?? json['nombre'] as String,
        contadorUso: json['contadorUso'] as int? ?? 0,
      );
}

/// Favoritos del niño (RF-10), guardados en la tabla favorito de SQLite.
/// Se mantienen también en memoria para que la barra inferior se dibuje sin esperar a la base.
class FavoritosService extends ChangeNotifier {
  static final FavoritosService _instance = FavoritosService._internal();
  factory FavoritosService() => _instance;
  FavoritosService._internal();

  final BaseDatos _bd = BaseDatos();
  final List<FavoritoItem> _favoritos = [];
  bool _initialized = false;

  List<FavoritoItem> get favoritos {
    final copy = List<FavoritoItem>.from(_favoritos);
    copy.sort((a, b) => b.contadorUso.compareTo(a.contadorUso));
    return copy;
  }

  bool get isEmpty => _favoritos.isEmpty;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final db = await _bd.db;
      final filas = await db.query('favorito', orderBy: 'creado_ts ASC');
      _favoritos
        ..clear()
        ..addAll(filas.map(FavoritoItem.fromFila));
      _initialized = true;
      notifyListeners();
    } catch (_) {}
  }

  /// Vacía la lista en memoria (después de borrar los datos de la aplicación).
  void limpiarMemoria() {
    _favoritos.clear();
    _initialized = false;
    notifyListeners();
  }

  bool esFavorito(String id) {
    return _favoritos.any((f) => f.id == id);
  }

  Future<void> toggleFavorito(FavoritoItem item) async {
    final idx = _favoritos.indexWhere((f) => f.id == item.id);
    try {
      final db = await _bd.db;
      if (idx >= 0) {
        _favoritos.removeAt(idx);
        await db.delete('favorito', where: 'id = ?', whereArgs: [item.id]);
      } else {
        _favoritos.add(item);
        await db.insert('favorito', item.toFila(DateTime.now().millisecondsSinceEpoch),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> registrarUso(String id) async {
    final idx = _favoritos.indexWhere((f) => f.id == id);
    if (idx >= 0) {
      _favoritos[idx].contadorUso += 1;
      try {
        final db = await _bd.db;
        await db.rawUpdate('UPDATE favorito SET contador_uso = contador_uso + 1 WHERE id = ?', [id]);
      } catch (_) {}
      notifyListeners();
    }
  }

  Future<void> eliminarFavorito(String id) async {
    _favoritos.removeWhere((f) => f.id == id);
    try {
      final db = await _bd.db;
      await db.delete('favorito', where: 'id = ?', whereArgs: [id]);
    } catch (_) {}
    notifyListeners();
  }
}
