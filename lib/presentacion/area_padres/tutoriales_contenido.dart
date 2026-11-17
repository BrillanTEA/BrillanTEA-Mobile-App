import 'package:flutter/material.dart';

/// Contenido de los tutoriales de 7 pantallas por módulo (US1502; Figma «Tutorial · <Módulo> · 0…6»):
/// «Antes de empezar», 5 pasos con la captura del módulo y «Listo» con 3 consejos.
/// Situaciones no tiene tutorial por pasos en el Figma y sigue con su detalle.

class PasoTutorial {
  final String titulo;
  final String texto;
  const PasoTutorial(this.titulo, this.texto);
}

class GuiaTutorial {
  /// Frase grande del recuadro de «Antes de empezar».
  final String idea;
  final String paraQueSirve;
  final List<PasoTutorial> pasos;
  /// Texto bajo «Cómo acompañar» en la pantalla «Listo».
  final String comoAcompanar;
  final List<String> consejos;
  final Color acento;

  const GuiaTutorial({
    required this.idea,
    required this.paraQueSirve,
    required this.pasos,
    required this.comoAcompanar,
    required this.consejos,
    required this.acento,
  });

  /// Captura del paso n (1 a 5): assets/images/tutoriales/<clave>_<n>.png
  static String imagenPaso(String clave, int n) => 'assets/images/tutoriales/${clave}_$n.png';
}

const Map<String, GuiaTutorial> guiasTutorial = {
  'camara': GuiaTutorial(
    idea: 'El niño apunta a un objeto y la app le dice qué es.',
    paraQueSirve: 'Cámara muestra el dibujo y la palabra de un objeto real. Tú acompañas y lo nombran juntos.',
    pasos: [
      PasoTutorial('Abre la cámara', 'En Inicio, toca Cámara.'),
      PasoTutorial('Apunta a un objeto', 'Apunta el teléfono al objeto. Pon solo uno en el cuadro.'),
      PasoTutorial('Toca ¿Qué es esto?', 'Con el objeto en el cuadro, toca el botón de la cámara.'),
      PasoTutorial('Toca el objeto', 'La app marca lo que ve. Toca el objeto que quieres conocer.'),
      PasoTutorial('Mira y escucha', 'Verán el dibujo y la palabra. Toca Escuchar para oírla.'),
    ],
    comoAcompanar: 'Sesiones cortas. Si el niño se cansa o se frustra, paren y sigan otro día.',
    consejos: [
      'Acerquen un objeto real y digan su nombre juntos.',
      'Si no lo reconoce, busquen más luz o un solo objeto.',
      'Después, busquen la misma palabra en Vocabulario.',
    ],
    acento: Color(0xFFC0754F),
  ),
  'comunicacion': GuiaTutorial(
    idea: 'El niño toca imágenes para pedir lo que necesita o responder.',
    paraQueSirve: 'Comunicación le da dibujos para pedir, armar frases y decir sí o no. Tú acompañas y le respondes.',
    pasos: [
      PasoTutorial('Elige qué hacer', 'Hay tres opciones: pedir algo, armar una frase y responder.'),
      PasoTutorial('Pide algo', 'En Pedir algo, el niño toca lo que necesita.'),
      PasoTutorial('Elige la opción', 'Toca el dibujo de lo que quiere, por ejemplo agua.'),
      PasoTutorial('Arma una frase', 'En Mi frase se elige paso a paso. Primero, cómo empieza.'),
      PasoTutorial('Escucha la frase', 'Al terminar, la app muestra la frase y la dice en voz alta.'),
    ],
    comoAcompanar: 'Sesiones cortas. Si el niño se cansa o se frustra, paren y sigan otro día.',
    consejos: [
      'Di la palabra en voz alta cuando el niño toque el dibujo.',
      'Dale lo que pidió, o explícale con calma por qué ahora no.',
      'Celebra cada intento, aunque se equivoque.',
    ],
    acento: Color(0xFF4E86A0),
  ),
  'vocabulario': GuiaTutorial(
    idea: 'El niño ve y escucha cada palabra. Todavía no tiene que decirla.',
    paraQueSirve: 'Vocabulario enseña a reconocer palabras. Tú acompañas; la app las muestra y las dice.',
    pasos: [
      PasoTutorial('Elige una categoría', 'Vocabulario tiene 6 categorías: animales, colores, números, letras, frutas y formas. Toca una para empezar.'),
      PasoTutorial('Toca una palabra', 'Cada tarjeta es una palabra. Tócala para verla en grande.'),
      PasoTutorial('Escucha y avanza', 'Escuchar dice la palabra en voz alta. Siguiente y Anterior cambian de palabra.'),
      PasoTutorial('Guarda las favoritas', 'Toca la estrella y la palabra aparecerá en Favoritos, para volver a ella rápido.'),
      PasoTutorial('Aprende cada letra', 'En Letras verás solo la letra, grande y sin dibujos, para que el niño se fije en ella.'),
    ],
    comoAcompanar: 'Sesiones cortas. Si el niño se cansa o se frustra, paren y sigan otro día.',
    consejos: [
      'Siéntate a su lado y di la palabra mientras la escucha.',
      'Señala el objeto real cuando lo tengan cerca.',
      'Repitan las mismas palabras varios días antes de pasar a otras.',
    ],
    acento: Color(0xFFA85D77),
  ),
  'rutinas': GuiaTutorial(
    idea: 'Cada rutina divide una tarea en pasos con dibujos.',
    paraQueSirve: 'Rutinas ayuda al niño a saber qué sigue. Tú acompañas y celebran cada paso.',
    pasos: [
      PasoTutorial('Elige una categoría', 'Hay categorías: Higiene, Ropa, Comida, Hogar y Juegos.'),
      PasoTutorial('Elige una rutina', 'Toca la rutina que van a hacer, por ejemplo Lavado de manos.'),
      PasoTutorial('Mira los pasos', 'Verán todos los pasos antes de empezar. Toca Continuar.'),
      PasoTutorial('Un paso a la vez', 'Cada paso tiene su dibujo. Al terminarlo, toca ¡Terminé!'),
      PasoTutorial('Gana una medalla', 'Si los premios están activos, al terminar gana una medalla.'),
    ],
    comoAcompanar: 'Sesiones cortas. Si el niño se cansa o se frustra, paren y sigan otro día.',
    consejos: [
      'Hagan la rutina a la misma hora cada día.',
      'Deja que lo intente solo; ayuda solo si lo necesita.',
      'Celebra cada paso, no solo el final.',
    ],
    acento: Color(0xFF5E9E6A),
  ),
  'emociones': GuiaTutorial(
    idea: 'El niño elige una cara para decir cómo se siente.',
    paraQueSirve: 'Emociones le ayuda a nombrar lo que siente. Tú acompañas y le muestras qué hacer.',
    pasos: [
      PasoTutorial('Elige una cara', 'Cada cara es una emoción. Toca la que se parece a cómo se siente.'),
      PasoTutorial('Desliza para ver más', 'Hay más emociones abajo, como sorprendido y aburrido.'),
      PasoTutorial('Mira la respuesta', 'La app dice la emoción y que está bien sentirla.'),
      PasoTutorial('Ve a Calma', 'Si quiere calmarse, toca Calma para hacer un ejercicio.'),
      PasoTutorial('Guarda las favoritas', 'Toca la estrella de una emoción para encontrarla rápido en Favoritos.'),
    ],
    comoAcompanar: 'Sesiones cortas. Si el niño se cansa o se frustra, paren y sigan otro día.',
    consejos: [
      'Nombra la emoción con él: «Veo que estás triste».',
      'Escucha primero; no corrijas ni expliques todavía.',
      'Si se desborda, hagan un ejercicio de Calma juntos.',
    ],
    acento: Color(0xFF8A7BB8),
  ),
  'calma': GuiaTutorial(
    idea: 'Calma ayuda al niño a tranquilizarse con ejercicios cortos.',
    paraQueSirve: 'Hay tres ejercicios: respirar, descansar y apretar y soltar. Tú acompañas y ves cómo termina.',
    pasos: [
      PasoTutorial('Elige un ejercicio', 'Respirar, Descansar o Aprieta y suelta. Toca el que quieras.'),
      PasoTutorial('Sigue las indicaciones', 'La pantalla dice cuándo inhalar y exhalar, con una cuenta de 4 segundos.'),
      PasoTutorial('¿Cómo te sientes ahora?', 'Al terminar, el niño elige si se siente mejor, igual o peor.'),
      PasoTutorial('Pide ayuda', 'Si sigue mal, aparece Pedir ayuda. El adulto toca Soy el adulto.'),
      PasoTutorial('Lee el aviso', 'Dice qué sintió, qué intentó y qué puedes hacer ahora.'),
    ],
    comoAcompanar: 'Sugerencias generales. No reemplazan la guía de su especialista.',
    consejos: [
      'Acércate y háblale bajito, con pocas palabras.',
      'Baja la luz y el ruido si puedes.',
      'Espera a que se calme antes de explicar o corregir.',
    ],
    acento: Color(0xFF4E9A8F),
  ),
};
