import 'dart:convert';

import 'package:flutter/services.dart';

import '../datos/base_datos.dart';

class CatalogoItem {
  final String clave;
  final String nombre;
  final String? terminoArasaac;
  final String? fraseApoyo;
  final String? fraseFueraRutina;
  final String? frasePeticion;
  /// Clase que entrega YOLO26s (0 a 34); null en los pictogramas extra de contexto.
  final int? idModelo;
  final String? categoria;
  final int? rutinaId;
  final int? paso;
  final String? avisoAnticipacion;
  final String archivoPictograma;
  final bool esRutina;

  CatalogoItem({
    required this.clave,
    required this.nombre,
    this.terminoArasaac,
    this.fraseApoyo,
    this.fraseFueraRutina,
    this.frasePeticion,
    this.idModelo,
    this.categoria,
    this.rutinaId,
    this.paso,
    this.avisoAnticipacion,
    required this.archivoPictograma,
    this.esRutina = false,
  });

  String get assetPath => 'assets/pictogramas/$archivoPictograma';
}

class CatalogoService {
  static final CatalogoService _instance = CatalogoService._internal();
  factory CatalogoService() => _instance;
  CatalogoService._internal();

  final List<CatalogoItem> _items = [];
  final Map<String, CatalogoItem> _byClave = {};
  bool _loaded = false;

  List<CatalogoItem> get items => _items;
  bool get isLoaded => _loaded;

  /// Lee el catálogo desde SQLite (tablas rutina y objeto, cargadas desde catalogo.json en el
  /// primer uso por BaseDatos). Si la base falla, lo lee directamente del JSON empaquetado.
  Future<void> load() async {
    if (_loaded) return;
    try {
      await _cargarDesdeBase();
      if (_items.isNotEmpty) {
        _loaded = true;
        return;
      }
    } catch (_) {}
    await _cargarDesdeJson();
  }

  // YOLO26s devuelve la clave del catálogo como etiqueta (p. ej. "jabon"), así que basta un mapa por clave.
  void _agregar(CatalogoItem item) {
    _items.add(item);
    _byClave[item.clave] = item;
  }

  Future<void> _cargarDesdeBase() async {
    final db = await BaseDatos().db;
    final rutinas = await db.query('rutina', orderBy: 'orden ASC');
    final objetos = await db.query('objeto', orderBy: 'orden ASC');
    _items.clear();
    _byClave.clear();
    for (final r in rutinas) {
      _agregar(CatalogoItem(
        clave: 'rutina_${r['id']}',
        nombre: r['nombre'] as String,
        terminoArasaac: r['termino_arasaac'] as String?,
        categoria: 'Rutina completa (${r['ambito']})',
        archivoPictograma: r['archivo_pictograma'] as String? ?? 'rutina_${r['id']}_8975.png',
        esRutina: true,
      ));
    }
    for (final o in objetos) {
      final extra = o['tipo'] == 'extra';
      _agregar(
        CatalogoItem(
          clave: o['clave'] as String,
          nombre: o['nombre'] as String,
          terminoArasaac: o['termino_arasaac'] as String?,
          fraseApoyo: o['frase_apoyo'] as String?,
          fraseFueraRutina: o['frase_fuera_rutina'] as String?,
          frasePeticion: o['frase_peticion'] as String?,
          idModelo: extra ? null : o['id_modelo'] as int?,
          categoria: o['categoria'] as String? ?? (extra ? 'Contexto' : 'General'),
          rutinaId: o['rutina_id'] as int?,
          paso: o['paso'] as int?,
          avisoAnticipacion: o['aviso_anticipacion'] as String?,
          archivoPictograma: o['archivo_pictograma'] as String? ?? '${o['clave']}.png',
          esRutina: false,
        ),
      );
    }
  }

  /// Respaldo: lectura directa de assets/catalogo.json (como antes de SQLite).
  Future<void> _cargarDesdeJson() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/catalogo.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      _items.clear();
      _byClave.clear();

      final rutinas = data['rutinas'] as List? ?? [];
      for (final r in rutinas) {
        final item = CatalogoItem(
          clave: 'rutina_${r['id']}',
          nombre: r['nombre'] as String,
          terminoArasaac: r['termino_arasaac'] as String?,
          categoria: 'Rutina completa (${r['ambito']})',
          archivoPictograma: r['archivo_pictograma'] as String? ?? 'rutina_${r['id']}_8975.png',
          esRutina: true,
        );
        _items.add(item);
        _byClave[item.clave] = item;
      }

      final objetos = data['objetos'] as List? ?? [];
      for (final o in objetos) {
        final item = CatalogoItem(
          clave: o['clave'] as String,
          nombre: o['nombre'] as String,
          terminoArasaac: o['termino_arasaac'] as String?,
          fraseApoyo: o['frase_apoyo'] as String?,
          fraseFueraRutina: o['frase_fuera_rutina'] as String?,
          frasePeticion: o['frase_peticion'] as String?,
          idModelo: o['id_modelo'] as int?,
          categoria: o['categoria'] as String? ?? 'General',
          rutinaId: o['rutina_id'] as int?,
          paso: o['paso'] as int?,
          avisoAnticipacion: o['aviso_anticipacion'] as String?,
          archivoPictograma: o['archivo_pictograma'] as String? ?? '${o['clave']}.png',
          esRutina: false,
        );
        _items.add(item);
        _byClave[item.clave] = item;
      }

      // Pictogramas extra de contexto (colegio)
      final extras = data['extra'] as List? ?? [];
      for (final e in extras) {
        final item = CatalogoItem(
          clave: e['clave'] as String,
          nombre: e['nombre'] as String,
          terminoArasaac: e['termino_arasaac'] as String?,
          categoria: 'Contexto',
          archivoPictograma: e['archivo_pictograma'] as String? ?? 'colegio_32446.png',
          esRutina: false,
        );
        _items.add(item);
        _byClave[item.clave] = item;
      }

      _loaded = true;
    } catch (e) {
      // Sin catálogo la cámara sigue funcionando, solo sin pictogramas.
    }
  }

  /// Busca el objeto por la etiqueta que entrega el modelo (la clave del catálogo).
  CatalogoItem? findPorEtiqueta(String? etiqueta) {
    if (etiqueta == null) return null;
    return _byClave[etiqueta.toLowerCase().trim()];
  }

  CatalogoItem? findByClave(String clave) {
    return _byClave[clave];
  }
}
