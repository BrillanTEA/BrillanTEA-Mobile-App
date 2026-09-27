import 'rutinas_service.dart';

// Rutinas de la app y su lógica (Motor de Rutinas). Las pantallas solo las muestran.
// Fuente: Figma BrillanTEA UX/UI, página Mockups (pasos, tiempos, etiquetas AHORA/DESPUÉS y cierre).

const String _pic = 'assets/pictogramas/rutinas';

/// Un paso de una rutina.
class PasoRutina {
  final int numero;
  final String nombre;

  /// Etiqueta corta de las tarjetas AHORA / DESPUÉS (como en el Figma).
  final String nombreCorto;
  final String fraseVoz;
  final String archivoPictograma;

  /// Temporizador opcional del paso, en segundos (RF-04, US504). null = sin temporizador.
  /// Los tiempos son los del Figma y debe validarlos el especialista.
  final int? segundos;

  const PasoRutina({
    required this.numero,
    required this.nombre,
    required this.nombreCorto,
    required this.fraseVoz,
    required this.archivoPictograma,
    this.segundos,
  });
}

class RutinaItem {
  final int id;
  final String nombre;
  final String categoria;
  final String assetIcono;

  /// Pictograma del objeto del catálogo que abre «Ir a la rutina» desde la cámara.
  /// Solo el objeto del PRIMER paso la abre. null = ningún objeto la abre (Ir a comer).
  final String? assetObjetoInicio;

  /// Texto bajo «¡Muy bien!» en la pantalla de cierre.
  final String mensajeFinal;
  final List<PasoRutina> pasos;

  const RutinaItem({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.assetIcono,
    required this.assetObjetoInicio,
    required this.mensajeFinal,
    required this.pasos,
  });
}

const List<RutinaItem> rutinasApp = [
  RutinaItem(
    id: 1,
    nombre: 'Lavado de manos',
    categoria: 'Higiene',
    assetIcono: 'assets/images/rut_lavado_manos.png',
    assetObjetoInicio: 'assets/pictogramas/cano_2414.png',
    mensajeFinal: 'Terminaste el lavado de manos.',
    pasos: [
      PasoRutina(
        numero: 1,
        nombre: 'Abrir el caño',
        nombreCorto: 'Abrir caño',
        fraseVoz: 'Abre el caño y moja tus manos.',
        archivoPictograma: '$_pic/abrir_el_cano.png',
      ),
      PasoRutina(
        numero: 2,
        nombre: 'Enjabonarme',
        nombreCorto: 'Enjabonarme',
        fraseVoz: 'Pon jabón y frota tus manos.',
        archivoPictograma: '$_pic/enjabonarme.png',
        segundos: 10,
      ),
      PasoRutina(
        numero: 3,
        nombre: 'Lavarme las manos',
        nombreCorto: 'Lavarme',
        fraseVoz: 'Enjuaga tus manos con agua.',
        archivoPictograma: '$_pic/lavarme_las_manos.png',
        segundos: 12,
      ),
      PasoRutina(
        numero: 4,
        nombre: 'Secarme con la toalla',
        nombreCorto: 'Secarme',
        fraseVoz: 'Seca tus manos con la toalla.',
        archivoPictograma: '$_pic/secarme_con_la_toalla.png',
        segundos: 10,
      ),
    ],
  ),
  RutinaItem(
    id: 2,
    nombre: 'Cepillado de dientes',
    categoria: 'Higiene',
    assetIcono: 'assets/images/rut_cepillado.png',
    assetObjetoInicio: 'assets/pictogramas/pasta_dental_2858.png',
    mensajeFinal: 'Terminaste el cepillado de dientes.',
    pasos: [
      PasoRutina(
        numero: 1,
        nombre: 'Poner pasta al cepillo',
        nombreCorto: 'Poner pasta',
        fraseVoz: 'Pon un poquito de pasta en tu cepillo.',
        archivoPictograma: '$_pic/poner_pasta_en_el_cepillo.png',
      ),
      PasoRutina(
        numero: 2,
        nombre: 'Cepillarme los dientes',
        nombreCorto: 'Cepillarme',
        fraseVoz: 'Cepilla tus dientes arriba y abajo.',
        archivoPictograma: '$_pic/cepillarme_los_dientes.png',
        segundos: 120,
      ),
      PasoRutina(
        numero: 3,
        nombre: 'Enjuagarme la boca',
        nombreCorto: 'Enjuagarme',
        fraseVoz: 'Enjuaga tu boca con agua.',
        archivoPictograma: '$_pic/enjuagarme_la_boca.png',
        segundos: 15,
      ),
      PasoRutina(
        numero: 4,
        nombre: 'Lavar mi cepillo',
        nombreCorto: 'Lavar cepillo',
        fraseVoz: 'Lava tu cepillo con agua.',
        archivoPictograma: '$_pic/lavar_mi_cepillo.png',
        segundos: 10,
      ),
      PasoRutina(
        numero: 5,
        nombre: 'Guardar mi cepillo',
        nombreCorto: 'Guardarlo',
        fraseVoz: 'Guarda tu cepillo en su lugar.',
        archivoPictograma: '$_pic/guardar_mi_cepillo.png',
      ),
    ],
  ),
  RutinaItem(
    id: 3,
    nombre: 'Vestirme',
    categoria: 'Ropa',
    assetIcono: 'assets/images/rut_vestirme.png',
    assetObjetoInicio: 'assets/pictogramas/uniforme_7233.png',
    mensajeFinal: 'Ya te vestiste solo.',
    pasos: [
      PasoRutina(
        numero: 1,
        nombre: 'Elegir mi ropa',
        nombreCorto: 'Elegir ropa',
        fraseVoz: 'Elige la ropa que te vas a poner.',
        archivoPictograma: '$_pic/ropa.png',
      ),
      PasoRutina(
        numero: 2,
        nombre: 'Ponerme el polo',
        nombreCorto: 'Polo',
        fraseVoz: 'Ponte el polo pasando la cabeza.',
        archivoPictograma: '$_pic/vestir.png',
        segundos: 60,
      ),
      PasoRutina(
        numero: 3,
        nombre: 'Ponerme el pantalón',
        nombreCorto: 'Pantalón',
        fraseVoz: 'Ponte el pantalón, una pierna y luego la otra.',
        archivoPictograma: '$_pic/subir_el_pantalon.png',
        segundos: 120,
      ),
      PasoRutina(
        numero: 4,
        nombre: 'Ponerme las medias',
        nombreCorto: 'Medias',
        fraseVoz: 'Ponte una media en cada pie.',
        archivoPictograma: '$_pic/poner_el_calcetin.png',
        segundos: 60,
      ),
      PasoRutina(
        numero: 5,
        nombre: 'Ponerme los zapatos',
        nombreCorto: 'Zapatos',
        fraseVoz: 'Ponte los zapatos.',
        archivoPictograma: '$_pic/calzar.png',
        segundos: 120,
      ),
    ],
  ),
  RutinaItem(
    id: 4,
    nombre: 'Ir a comer',
    categoria: 'Comida',
    assetIcono: 'assets/images/rut_comer.png',
    assetObjetoInicio: null, // ningún objeto de la cámara abre esta rutina
    mensajeFinal: 'Terminaste de comer.',
    pasos: [
      PasoRutina(
        numero: 1,
        nombre: 'Esperar mi comida',
        nombreCorto: 'Esperar',
        fraseVoz: 'Siéntate y espera tu comida.',
        archivoPictograma: '$_pic/esperar_la_comida.png',
      ),
      PasoRutina(
        numero: 2,
        nombre: 'Comer',
        nombreCorto: 'Comer',
        fraseVoz: 'Come con calma.',
        archivoPictograma: '$_pic/comer.png',
        segundos: 600,
      ),
      PasoRutina(
        numero: 3,
        nombre: 'Beber',
        nombreCorto: 'Beber',
        fraseVoz: 'Toma un poco de agua.',
        archivoPictograma: '$_pic/beber.png',
        segundos: 60,
      ),
      PasoRutina(
        numero: 4,
        nombre: 'Limpiarme la boca',
        nombreCorto: 'Limpiar boca',
        fraseVoz: 'Limpia tu boca con la servilleta.',
        archivoPictograma: '$_pic/limpiar_la_boca.png',
      ),
      PasoRutina(
        numero: 5,
        nombre: 'Recoger el plato',
        nombreCorto: 'Recoger plato',
        fraseVoz: 'Recoge tu plato de la mesa.',
        archivoPictograma: '$_pic/quitar_la_mesa.png',
      ),
      PasoRutina(
        numero: 6,
        nombre: 'Dejar el plato en el fregadero',
        nombreCorto: 'Dejar plato',
        fraseVoz: 'Deja tu plato en el fregadero.',
        archivoPictograma: '$_pic/fregadero.png',
      ),
    ],
  ),
  RutinaItem(
    id: 5,
    nombre: 'Tender mi cama',
    categoria: 'Hogar',
    assetIcono: 'assets/images/rut_cama.png',
    assetObjetoInicio: 'assets/pictogramas/cama_25900.png',
    mensajeFinal: 'Tu cama quedó lista.',
    pasos: [
      PasoRutina(
        numero: 1,
        nombre: 'Levantarme de la cama',
        nombreCorto: 'Levantarme',
        fraseVoz: 'Levántate de la cama.',
        archivoPictograma: '$_pic/levantar_de_la_cama.png',
      ),
      PasoRutina(
        numero: 2,
        nombre: 'Hacer la cama',
        nombreCorto: 'Hacer cama',
        fraseVoz: 'Estira la sábana de abajo.',
        archivoPictograma: '$_pic/hacer_la_cama.png',
        segundos: 30,
      ),
      PasoRutina(
        numero: 3,
        nombre: 'Poner la sábana de arriba',
        nombreCorto: 'Sábana',
        fraseVoz: 'Pon la sábana de arriba.',
        archivoPictograma: '$_pic/sabana.png',
        segundos: 30,
      ),
      PasoRutina(
        numero: 4,
        nombre: 'Poner el edredón',
        nombreCorto: 'Edredón',
        fraseVoz: 'Pon el edredón encima.',
        archivoPictograma: '$_pic/edredon.png',
        segundos: 30,
      ),
      PasoRutina(
        numero: 5,
        nombre: 'Poner la almohada',
        nombreCorto: 'Almohada',
        fraseVoz: 'Pon la almohada en su lugar.',
        archivoPictograma: '$_pic/almohada.png',
      ),
    ],
  ),
];

/// Rutinas activas que se abren con este objeto (US405 del Product Backlog; RF-03).
/// Solo cuenta el objeto del PRIMER paso (assetObjetoInicio). Ir a comer no tiene objeto.
Future<List<RutinaItem>> rutinasQueEmpiezanCon(String assetObjeto) async {
  final desactivadas = await RutinasService().getRutinasDesactivadas();
  return rutinasApp
      .where((r) => r.assetObjetoInicio == assetObjeto && !desactivadas.contains(r.id))
      .toList();
}
