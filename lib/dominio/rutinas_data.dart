import 'package:flutter/material.dart';

/// Modelo de información básica de una rutina
class RutinaInfo {
  final int id;
  final String nombre;
  final String categoria;
  final int totalPasos;
  final String assetIcono;
  final IconData fallbackIcon;

  const RutinaInfo({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.totalPasos,
    required this.assetIcono,
    required this.fallbackIcon,
  });
}

/// Modelo de información de una categoría de rutinas
class CategoriaRutinaInfo {
  final String nombre;
  final IconData icono;
  final List<int> rutinaIds;

  const CategoriaRutinaInfo({
    required this.nombre,
    required this.icono,
    required this.rutinaIds,
  });
}

/// Catálogo canónico de rutinas y categorías en la aplicación
class RutinasCatalogo {
  static const List<RutinaInfo> todasLasRutinas = [
    RutinaInfo(
      id: 1,
      nombre: 'Lavado de manos',
      categoria: 'Higiene',
      totalPasos: 4,
      assetIcono: 'assets/images/rut_lavado_manos.png',
      fallbackIcon: Icons.wash_rounded,
    ),
    RutinaInfo(
      id: 2,
      nombre: 'Cepillado de dientes',
      categoria: 'Higiene',
      totalPasos: 5,
      assetIcono: 'assets/images/rut_cepillado.png',
      fallbackIcon: Icons.cleaning_services_rounded,
    ),
    RutinaInfo(
      id: 3,
      nombre: 'Vestirme',
      categoria: 'Ropa',
      totalPasos: 5,
      assetIcono: 'assets/images/rut_vestirme.png',
      fallbackIcon: Icons.checkroom_rounded,
    ),
    RutinaInfo(
      id: 4,
      nombre: 'Ir a comer',
      categoria: 'Comida',
      totalPasos: 6,
      assetIcono: 'assets/images/rut_comer.png',
      fallbackIcon: Icons.restaurant_rounded,
    ),
    RutinaInfo(
      id: 5,
      nombre: 'Tender mi cama',
      categoria: 'Hogar',
      totalPasos: 5,
      assetIcono: 'assets/images/rut_cama.png',
      fallbackIcon: Icons.bed_rounded,
    ),
  ];

  static const List<CategoriaRutinaInfo> categorias = [
    CategoriaRutinaInfo(
      nombre: 'Higiene',
      icono: Icons.wash_rounded,
      rutinaIds: [1, 2],
    ),
    CategoriaRutinaInfo(
      nombre: 'Ropa',
      icono: Icons.checkroom_rounded,
      rutinaIds: [3],
    ),
    CategoriaRutinaInfo(
      nombre: 'Comida',
      icono: Icons.restaurant_rounded,
      rutinaIds: [4],
    ),
    CategoriaRutinaInfo(
      nombre: 'Hogar',
      icono: Icons.bed_rounded,
      rutinaIds: [5],
    ),
  ];

  static List<RutinaInfo> porCategoria(String categoria) {
    return todasLasRutinas.where((r) => r.categoria == categoria).toList();
  }

  static RutinaInfo? porId(int id) {
    try {
      return todasLasRutinas.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
