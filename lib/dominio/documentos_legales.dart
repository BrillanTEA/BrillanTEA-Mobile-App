// Textos de los Términos y condiciones y de la Política de privacidad (Figma: Términos y privacidad,
// hojas 590:2 y 591:2). Se guardan dentro de la app para leerlos sin conexión (US901).
// Generado desde el Figma: si cambia el texto allá, se vuelve a generar este archivo.

/// Tramo de texto dentro de un párrafo: [negrita] para los números y los rótulos; [acento] los pinta
/// con el color del bloque (teal en los números, gris en los rótulos de las tarjetas).
class TramoLegal {
  final String texto;
  final bool negrita;
  final bool acento;
  const TramoLegal(this.texto, {this.negrita = false, this.acento = false});
}

enum TipoBloqueLegal { titulo, parrafo, vineta, tarjeta, espacio, divisor, pie }

/// Un bloque del documento, en el orden en que se muestra en la hoja.
class BloqueLegal {
  final TipoBloqueLegal tipo;
  final String texto;
  final List<TramoLegal> tramos;
  final List<List<TramoLegal>> lineas;

  const BloqueLegal.titulo(this.texto)
      : tipo = TipoBloqueLegal.titulo, tramos = const [], lineas = const [];
  const BloqueLegal.pie(this.texto)
      : tipo = TipoBloqueLegal.pie, tramos = const [], lineas = const [];
  const BloqueLegal.parrafo(this.tramos)
      : tipo = TipoBloqueLegal.parrafo, texto = '', lineas = const [];
  const BloqueLegal.vineta(this.tramos)
      : tipo = TipoBloqueLegal.vineta, texto = '', lineas = const [];
  const BloqueLegal.tarjeta(this.texto, this.lineas)
      : tipo = TipoBloqueLegal.tarjeta, tramos = const [];
  const BloqueLegal.espacio()
      : tipo = TipoBloqueLegal.espacio, texto = '', tramos = const [], lineas = const [];
  const BloqueLegal.divisor()
      : tipo = TipoBloqueLegal.divisor, texto = '', tramos = const [], lineas = const [];
}

/// Documento legal completo: título y versión de la cabecera de la hoja, y su contenido.
class DocumentoLegal {
  final String titulo;
  final String version;
  final List<BloqueLegal> bloques;
  const DocumentoLegal({required this.titulo, required this.version, required this.bloques});
}

/// Versión de los documentos que el adulto acepta en el primer uso (la misma del encabezado y del pie).
const String versionDocumentosLegales = '1.0';

const DocumentoLegal terminosYCondiciones = DocumentoLegal(
  titulo: 'Términos y condiciones',
  version: 'Versión 1.0 · 16 de noviembre de 2026',
  bloques: _bloquesTerminos,
);

const DocumentoLegal politicaDePrivacidad = DocumentoLegal(
  titulo: 'Política de privacidad',
  version: 'Versión 1.0 · 16 de noviembre de 2026',
  bloques: _bloquesPolitica,
);

const List<BloqueLegal> _bloquesTerminos = [
  BloqueLegal.titulo('1. Qué es BrillanTEA y quién la ofrece'),
  BloqueLegal.parrafo([TramoLegal('1.1.', negrita: true, acento: true), TramoLegal(' BrillanTEA es una aplicación para Android que funciona sin conexión a internet. Ofrece apoyos visuales con pictogramas, voz y pasos breves para niñas y niños con trastorno del espectro autista (TEA) de 6 a 10 años, quienes deben usarla siempre acompañados por un adulto responsable.')]),
  BloqueLegal.parrafo([TramoLegal('1.2.', negrita: true, acento: true), TramoLegal(' BrillanTEA es una herramienta de apoyo. No es un producto sanitario: no diagnostica, no trata ni cura ninguna condición, y no sustituye la evaluación, la terapia ni las indicaciones de profesionales de la salud o de la educación.')]),
  BloqueLegal.parrafo([TramoLegal('1.3.', negrita: true, acento: true), TramoLegal(' BrillanTEA es un proyecto académico desarrollado por Fabiola Espinoza (código u202214784) y Ricardo Barrutia (código u201714765), estudiantes de la Universidad Peruana de Ciencias Aplicadas (UPC), con domicilio en el Campus San Isidro de la UPC (Av. Salaverry 2255, San Isidro, Lima, Perú), y correos de contacto u201714765@upc.edu.pe y u202214784@upc.edu.pe (en adelante, «los Titulares»).')]),
  BloqueLegal.parrafo([TramoLegal('1.4.', negrita: true, acento: true), TramoLegal(' En estos términos, «adulto responsable» es la persona mayor de edad que registra al niño o niña en la aplicación y lo acompaña durante su uso.')]),
  BloqueLegal.parrafo([TramoLegal('1.5.', negrita: true, acento: true), TramoLegal(' Los Términos y condiciones y la Política de privacidad están guardados dentro de la aplicación y pueden leerse sin conexión en la pantalla «Términos y privacidad», al empezar, y en Área de padres → Ayuda y soporte → Acerca de.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('2. Qué incluye la aplicación'),
  BloqueLegal.parrafo([TramoLegal('2.1.', negrita: true, acento: true), TramoLegal(' Primer uso. Al abrir la aplicación por primera vez, el adulto responsable lee y acepta los Términos y condiciones y la Política de privacidad; registra sus datos (nombre, apellido, fecha de nacimiento, ciudad o distrito, sexo y relación con el niño o niña); crea un PIN de cuatro dígitos; y registra el perfil del niño o niña con su nombre, su edad y un avatar. Luego puede revisar los tutoriales o empezar a usar la aplicación.')]),
  BloqueLegal.parrafo([TramoLegal('2.2.', negrita: true, acento: true), TramoLegal(' Módulos para el niño o niña. La pantalla de Inicio presenta siete módulos:')]),
  BloqueLegal.vineta([TramoLegal('Cámara.', negrita: true), TramoLegal(' El niño o niña apunta a un objeto y la aplicación muestra su pictograma y dice su nombre en voz alta. Si el objeto tiene una rutina relacionada, ofrece ir a ella. El reconocimiento se realiza en el teléfono y puede equivocarse o no reconocer el objeto.')]),
  BloqueLegal.vineta([TramoLegal('Comunicación.', negrita: true), TramoLegal(' Permite pedir algo (comer, tomar, ir al baño, ayuda, jugar o expresar dolor), armar frases con pictogramas (por ejemplo, «Yo quiero agua») y responder Sí o No. La aplicación lee la frase en voz alta.')]),
  BloqueLegal.vineta([TramoLegal('Vocabulario.', negrita: true), TramoLegal(' Seis categorías (animales, colores, números, letras, frutas y formas), cada palabra con su pictograma, su separación en sílabas y su pronunciación en voz alta.')]),
  BloqueLegal.vineta([TramoLegal('Rutinas.', negrita: true), TramoLegal(' Rutinas organizadas por categoría (higiene, ropa, comida, hogar y juegos), explicadas paso a paso con las indicaciones «ahora» y «después», un tiempo sugerido y una medalla al terminar.')]),
  BloqueLegal.vineta([TramoLegal('Emociones.', negrita: true), TramoLegal(' El niño o niña elige cómo se siente y recibe una respuesta sencilla, con la opción de pasar al módulo Calma.')]),
  BloqueLegal.vineta([TramoLegal('Situaciones.', negrita: true), TramoLegal(' Historias breves, paso a paso, para repasar situaciones sociales y de seguridad, agrupadas en «Para estar seguro», «Cuando es difícil» y «Con otras personas» (por ejemplo, cruzar la calle, qué hacer si se pierde, ir al doctor o saludar).')]),
  BloqueLegal.vineta([TramoLegal('Calma.', negrita: true), TramoLegal(' Ejercicios guiados (respirar, descansar, apretar y soltar), la pregunta «¿Cómo te sientes ahora?» y la opción «Pedir ayuda», que muestra al adulto un aviso con lo que el niño o niña sintió y lo que intentó.')]),
  BloqueLegal.parrafo([TramoLegal('2.3.', negrita: true, acento: true), TramoLegal(' Funciones de apoyo. Favoritos reúne accesos directos a los pictogramas que el niño o niña usa con más frecuencia. Mis premios muestra las medallas obtenidas en las rutinas y la meta definida por el adulto; las medallas no tienen valor económico y el premio lo decide el adulto fuera de la aplicación. La aplicación también puede leer en voz alta textos e instrucciones.')]),
  BloqueLegal.parrafo([TramoLegal('2.4.', negrita: true, acento: true), TramoLegal(' Área de padres. Está protegida con PIN e incluye: Accesibilidad (tamaño de texto, sonidos, vibración y lectura en voz alta); Configuración (rutinas activas, cambio de PIN y premios con período y meta); Perfil del menor; Seguimiento (rutinas completadas, emoción frecuente, comparación con la semana anterior, pictogramas más usados, notas para el especialista y reporte descargable); Tutoriales de los siete módulos; Ayuda y soporte; Retirar consentimiento; y Borrar los datos.')]),
  BloqueLegal.parrafo([TramoLegal('2.5.', negrita: true, acento: true), TramoLegal(' Los nombres, imágenes de ejemplo, rutinas y pasos incluidos en la aplicación son ilustrativos. El adulto responsable puede activar o desactivar rutinas según las necesidades del niño o niña.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('3. Quién puede registrarse y aceptar'),
  BloqueLegal.parrafo([TramoLegal('3.1.', negrita: true, acento: true), TramoLegal(' Puede registrar al niño o niña y aceptar estos términos un adulto responsable: la madre, el padre, el tutor o el representante legal, o bien un cuidador, terapeuta, docente, técnico u otro profesional que acompañe al menor.')]),
  BloqueLegal.parrafo([TramoLegal('3.2.', negrita: true, acento: true), TramoLegal(' Si quien se registra no es la madre, el padre, el tutor ni el representante legal, declara contar con la autorización previa y expresa de este para registrar al niño o niña y aceptar estos términos en su nombre. El representante legal sigue siendo responsable de autorizar el uso de la aplicación.')]),
  BloqueLegal.parrafo([TramoLegal('3.3.', negrita: true, acento: true), TramoLegal(' Al registrarse, el adulto responsable ingresa su nombre, su apellido, su fecha de nacimiento, su ciudad o distrito, su sexo y su relación con el niño o niña; del niño o niña se ingresan su nombre, su edad y un avatar. Los campos de nombre y apellido admiten un solo nombre y un solo apellido, sin espacios: no se aceptan segundos nombres, segundos apellidos, alias ni sobrenombres.')]),
  BloqueLegal.parrafo([TramoLegal('3.4.', negrita: true, acento: true), TramoLegal(' El niño o niña no acepta ni consiente nada por sí mismo.')]),
  BloqueLegal.parrafo([TramoLegal('3.5.', negrita: true, acento: true), TramoLegal(' La aceptación se realiza mediante una casilla sin marcar, en la que el adulto declara que está de acuerdo con los Términos y condiciones y la Política de privacidad y que autoriza el tratamiento de los datos sensibles del niño o niña. Si no se marca, no es posible continuar.')]),
  BloqueLegal.parrafo([TramoLegal('3.6.', negrita: true, acento: true), TramoLegal(' Quien use la aplicación para registrar a un menor sin contar con la representación o autorización necesaria debe dejar de usarla y borrar los datos del dispositivo.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('4. Uso previsto y límites'),
  BloqueLegal.parrafo([TramoLegal('4.1.', negrita: true, acento: true), TramoLegal(' La aplicación está pensada para usarse con el acompañamiento de un adulto, en casa, en la escuela o en terapia. El adulto responsable decide cuándo, cómo y durante cuánto tiempo la usa el niño o niña.')]),
  BloqueLegal.parrafo([TramoLegal('4.2.', negrita: true, acento: true), TramoLegal(' Si existe desacuerdo entre los representantes del menor o una restricción judicial, el adulto responsable debe asegurarse de contar con la autorización necesaria antes de usar la aplicación.')]),
  BloqueLegal.parrafo([TramoLegal('4.3.', negrita: true, acento: true), TramoLegal(' Situaciones. Las historias sobre seguridad (por ejemplo, cruzar la calle o qué hacer si se pierde) sirven para repasar y anticipar. No reemplazan la supervisión ni la enseñanza en el lugar real, que siempre deben estar a cargo de un adulto.')]),
  BloqueLegal.parrafo([TramoLegal('4.4.', negrita: true, acento: true), TramoLegal(' Calma y Emociones. Los ejercicios, respuestas y avisos son sugerencias generales. No reemplazan la orientación del especialista ni sirven para atender una crisis. BrillanTEA no es un servicio de emergencia: si el niño, la niña o el adulto se encuentra en riesgo, contacte de inmediato a los servicios de emergencia o a un profesional. En el Perú, la Línea 113, opción 5, brinda orientación en salud mental.')]),
  BloqueLegal.parrafo([TramoLegal('4.5.', negrita: true, acento: true), TramoLegal(' Cámara. El reconocimiento puede fallar o confundir objetos y no indica si un objeto es seguro. El adulto debe supervisar su uso y evitar que el niño o niña apunte la cámara a personas o a objetos peligrosos.')]),
  BloqueLegal.parrafo([TramoLegal('4.6.', negrita: true, acento: true), TramoLegal(' Rutinas y premios. Los pasos y tiempos son referenciales. El adulto debe adaptarlos y supervisar las actividades que lo requieran (por ejemplo, el uso de agua caliente o de objetos de higiene). Las medallas son un refuerzo positivo, no una evaluación.')]),
  BloqueLegal.parrafo([TramoLegal('4.7.', negrita: true, acento: true), TramoLegal(' Seguimiento. Los resúmenes, comparaciones y conteos son referenciales y no constituyen una evaluación clínica ni educativa.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('5. Perfiles, uso sin conexión, notas y reportes'),
  BloqueLegal.parrafo([TramoLegal('5.1.', negrita: true, acento: true), TramoLegal(' La aplicación funciona sin internet y no requiere crear una cuenta en línea. La información de los perfiles se guarda únicamente en el dispositivo.')]),
  BloqueLegal.parrafo([TramoLegal('5.2.', negrita: true, acento: true), TramoLegal(' Los perfiles contienen solo los datos necesarios: los datos de registro del adulto responsable (nombre, apellido, fecha de nacimiento, ciudad o distrito, sexo y relación con el niño o niña) y el nombre, la edad y el avatar del niño o niña.')]),
  BloqueLegal.parrafo([TramoLegal('5.3.', negrita: true, acento: true), TramoLegal(' La seguridad de la información depende también del bloqueo de pantalla, de las actualizaciones del sistema y de quién tenga acceso al dispositivo. Se recomienda activar el bloqueo de pantalla y no prestar el teléfono desbloqueado.')]),
  BloqueLegal.parrafo([TramoLegal('5.4.', negrita: true, acento: true), TramoLegal(' La cámara se usa solo en el módulo Cámara y únicamente si el adulto concede el permiso de Android. Antes de solicitarlo, la aplicación explica para qué se usa. Las imágenes se analizan en el dispositivo y no se guardan ni se envían. El permiso puede retirarse en cualquier momento desde los ajustes de Android; los demás módulos siguen funcionando.')]),
  BloqueLegal.parrafo([TramoLegal('5.5.', negrita: true, acento: true), TramoLegal(' Notas y reportes. En Seguimiento, el adulto puede escribir notas para un especialista y descargar un reporte. Se recomienda no incluir en las notas diagnósticos, direcciones ni datos de terceros. Al descargar o compartir el reporte, el adulto decide dónde se guarda y con quién lo comparte; desde ese momento el archivo queda fuera de la aplicación y no se borra al desinstalarla.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('6. Área de padres y PIN'),
  BloqueLegal.parrafo([TramoLegal('6.1.', negrita: true, acento: true), TramoLegal(' El Área de padres está protegida con un PIN de cuatro dígitos para evitar que el niño o niña la modifique por accidente.')]),
  BloqueLegal.parrafo([TramoLegal('6.2.', negrita: true, acento: true), TramoLegal(' La custodia del PIN corresponde al adulto responsable. Debe elegir un PIN difícil de adivinar (que no sea una fecha de nacimiento ni una secuencia como 1234), no compartirlo con el menor y cambiarlo si sospecha que otra persona lo conoce. Los Titulares no pueden ver, recuperar ni restablecer el PIN, porque no tienen acceso al dispositivo.')]),
  BloqueLegal.parrafo([TramoLegal('6.3.', negrita: true, acento: true), TramoLegal(' Si el PIN se olvida, la aplicación ofrece una recuperación local mediante tres preguntas sobre los datos del perfil del adulto (nombre, apellido y ciudad o distrito). Tras tres respuestas incorrectas, esta opción se bloquea durante cinco minutos. Si no es posible recuperarlo, la única alternativa puede ser restablecer la aplicación, lo que borra los perfiles y el seguimiento.')]),
  BloqueLegal.parrafo([TramoLegal('6.4.', negrita: true, acento: true), TramoLegal(' El PIN no sustituye el bloqueo del dispositivo ni equivale a cifrar los datos. Las acciones realizadas con el PIN correcto se consideran realizadas por el adulto responsable.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('7. Pictogramas, contenido y licencias'),
  BloqueLegal.parrafo([TramoLegal('7.1.', negrita: true, acento: true), TramoLegal(' La mayoría de los pictogramas proceden de ARASAAC (https://arasaac.org), son propiedad del Gobierno de Aragón, fueron creados por Sergio Palao y se usan bajo la licencia Creative Commons BY-NC-SA 4.0 (reconocimiento, uso no comercial y compartir igual).')]),
  BloqueLegal.parrafo([TramoLegal('7.2.', negrita: true, acento: true), TramoLegal(' En cumplimiento de esa licencia, BrillanTEA se ofrece de forma gratuita, sin publicidad y sin compras dentro de la aplicación. Las adaptaciones de pictogramas realizadas para la aplicación (por ejemplo, las versiones de niña y de niño) se comparten bajo la misma licencia.')]),
  BloqueLegal.parrafo([TramoLegal('7.3.', negrita: true, acento: true), TramoLegal(' Las ilustraciones propias (avatares, escenas de Calma, imágenes de ejemplo de la Cámara e íconos), la tipografía y los demás recursos se usan conforme a sus respectivas licencias.')]),
  BloqueLegal.parrafo([TramoLegal('7.4.', negrita: true, acento: true), TramoLegal(' El código, el diseño de las pantallas y los textos originales pertenecen a sus autores, sin perjuicio de los derechos que correspondan a la UPC según su normativa, y se ofrecen para uso personal, educativo y terapéutico sin fines comerciales. No se permite copiar, vender ni redistribuir la aplicación sin autorización escrita.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('8. Uso aceptable y responsabilidad'),
  BloqueLegal.parrafo([TramoLegal('8.1.', negrita: true, acento: true), TramoLegal(' El adulto responsable se compromete a usar la aplicación solo para el fin previsto, a no ingresar datos de terceros sin autorización y a no usarla de forma contraria al interés superior del niño.')]),
  BloqueLegal.parrafo([TramoLegal('8.2.', negrita: true, acento: true), TramoLegal(' Está prohibido descompilar, modificar o eludir la aplicación, así como extraer o redistribuir sus contenidos.')]),
  BloqueLegal.parrafo([TramoLegal('8.3.', negrita: true, acento: true), TramoLegal(' La aplicación se ofrece «tal cual», sin garantía de que se adapte a las necesidades particulares de cada niño o niña. En la medida permitida por la ley, los Titulares no responden por daños derivados de un uso distinto del previsto, de la pérdida del dispositivo o del PIN, ni de decisiones clínicas o educativas tomadas únicamente a partir de la aplicación. Nada de lo anterior limita los derechos irrenunciables del usuario.')]),
  BloqueLegal.parrafo([TramoLegal('8.4.', negrita: true, acento: true), TramoLegal(' El adulto debe adaptar los pictogramas, las rutinas y los ejercicios a cada niño o niña y suspenderlos si observa malestar, sobrecarga sensorial o cualquier reacción adversa.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('9. Datos personales (resumen)'),
  BloqueLegal.parrafo([TramoLegal('9.1.', negrita: true, acento: true), TramoLegal(' Los responsables del tratamiento de los datos son los Titulares. El tratamiento se rige por la Ley N.° 29733, Ley de Protección de Datos Personales, y su Reglamento, aprobado por el Decreto Supremo N.° 016-2024-JUS. El detalle se encuentra en la Política de privacidad.')]),
  BloqueLegal.parrafo([TramoLegal('9.2.', negrita: true, acento: true), TramoLegal(' Todos los datos se guardan en el dispositivo. La aplicación no envía datos a los Titulares ni a terceros, no contiene publicidad ni herramientas de analítica, y no vende ni cede datos.')]),
  BloqueLegal.parrafo([TramoLegal('9.3.', negrita: true, acento: true), TramoLegal(' Por su relación con el TEA, los datos del niño o niña, sus emociones, su actividad en los módulos y las notas del adulto se tratan como datos sensibles y requieren consentimiento expreso, que se otorga en la casilla de aceptación.')]),
  BloqueLegal.parrafo([TramoLegal('9.4.', negrita: true, acento: true), TramoLegal(' El adulto responsable puede ver los datos en Área de padres (Perfil del menor y Seguimiento), corregir los del niño o niña en Perfil del menor, borrarlos en Área de padres → Borrar los datos y retirar su consentimiento en Área de padres → Retirar consentimiento.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('10. Cambios en estos términos'),
  BloqueLegal.parrafo([TramoLegal('10.1.', negrita: true, acento: true), TramoLegal(' Cualquier cambio se informará dentro de la aplicación junto con la fecha de la nueva versión. Si el cambio afecta de forma relevante qué datos se tratan o con qué finalidad, se solicitará nuevamente el consentimiento antes de aplicarlo.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('11. Retiro del consentimiento y fin del uso'),
  BloqueLegal.parrafo([TramoLegal('11.1.', negrita: true, acento: true), TramoLegal(' El adulto responsable puede dejar de usar la aplicación en cualquier momento.')]),
  BloqueLegal.parrafo([TramoLegal('11.2.', negrita: true, acento: true), TramoLegal(' También puede retirar su consentimiento en Área de padres → Retirar consentimiento. Al hacerlo, se borran todos los datos del dispositivo y la aplicación vuelve al inicio; para usarla otra vez hay que aceptar nuevamente. El retiro no afecta el tratamiento realizado antes.')]),
  BloqueLegal.parrafo([TramoLegal('11.3.', negrita: true, acento: true), TramoLegal(' Al desinstalar la aplicación, Android elimina sus datos locales, salvo las copias de seguridad que el adulto haya activado y los reportes que haya descargado.')]),
  BloqueLegal.parrafo([TramoLegal('11.4.', negrita: true, acento: true), TramoLegal(' Los Titulares pueden dejar de ofrecer la aplicación o alguna de sus funciones. En ese caso lo anunciarán con anticipación razonable, y la última versión instalada seguirá funcionando sin soporte.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('12. Contacto, soporte y plazos de respuesta'),
  BloqueLegal.parrafo([TramoLegal('12.1.', negrita: true, acento: true), TramoLegal(' Para consultas, reportes de fallas, solicitudes sobre datos personales o reclamos, el adulto responsable puede usar la sección «Ayuda y soporte» de la aplicación o escribir a u201714765@upc.edu.pe o u202214784@upc.edu.pe.')]),
  BloqueLegal.parrafo([TramoLegal('12.2.', negrita: true, acento: true), TramoLegal(' Los Titulares se comprometen a atender las comunicaciones en los siguientes plazos, contados en días hábiles desde el día siguiente a su recepción:')]),
  BloqueLegal.vineta([TramoLegal('Confirmación de recepción.', negrita: true), TramoLegal(' Hasta 2 días hábiles.')]),
  BloqueLegal.vineta([TramoLegal('Consultas, sugerencias y reportes de fallas.', negrita: true), TramoLegal(' Respuesta en un máximo de 5 días hábiles.')]),
  BloqueLegal.vineta([TramoLegal('Reclamos sobre el funcionamiento de la aplicación.', negrita: true), TramoLegal(' Respuesta en un máximo de 10 días hábiles.')]),
  BloqueLegal.vineta([TramoLegal('Solicitudes sobre datos personales.', negrita: true), TramoLegal(' En los plazos de la normativa de protección de datos: información, 8 días hábiles; acceso, 20 días hábiles; rectificación, cancelación y oposición, 10 días hábiles. Cuando las circunstancias lo justifiquen, estos plazos (salvo el de información) pueden ampliarse por única vez por un período igual, lo que se comunicará al solicitante.')]),
  BloqueLegal.parrafo([TramoLegal('12.3.', negrita: true, acento: true), TramoLegal(' Si el adulto considera que su solicitud sobre datos personales no fue atendida, puede acudir a la Autoridad Nacional de Protección de Datos Personales del Ministerio de Justicia y Derechos Humanos.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('13. Ley aplicable'),
  BloqueLegal.parrafo([TramoLegal('13.1.', negrita: true, acento: true), TramoLegal(' Estos términos se rigen por las leyes de la República del Perú. Ante cualquier controversia, las partes buscarán primero una solución amistosa; de no lograrse, serán competentes los jueces y tribunales del Distrito Judicial de Lima, sin perjuicio de los fueros que la ley reconozca al consumidor.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('14. Alcance territorial'),
  BloqueLegal.parrafo([TramoLegal('14.1.', negrita: true, acento: true), TramoLegal(' La aplicación está dirigida a personas que residen en el Perú y se ofrece en español.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('15. Disposiciones finales'),
  BloqueLegal.parrafo([TramoLegal('15.1.', negrita: true, acento: true), TramoLegal(' Si alguna cláusula fuera declarada nula o inaplicable, las demás mantendrán su validez.')]),
  BloqueLegal.parrafo([TramoLegal('15.2.', negrita: true, acento: true), TramoLegal(' La aplicación guarda en el dispositivo la fecha y la hora en que se aceptaron estos documentos, como constancia. Ese registro se borra junto con los demás datos.')]),
  BloqueLegal.parrafo([TramoLegal('15.3.', negrita: true, acento: true), TramoLegal(' Ante cualquier duda sobre el alcance de una cláusula, prevalece el texto completo de estos términos.')]),
  BloqueLegal.divisor(),
  BloqueLegal.pie('Fin del documento · Versión 1.0'),
];

const List<BloqueLegal> _bloquesPolitica = [
  BloqueLegal.titulo('1. Quiénes son los responsables'),
  BloqueLegal.parrafo([TramoLegal('Los responsables del tratamiento de los datos personales son Fabiola Espinoza (código u202214784) y Ricardo Barrutia (código u201714765), estudiantes de la Universidad Peruana de Ciencias Aplicadas (UPC), con domicilio en el Campus San Isidro de la UPC (Av. Salaverry 2255, San Isidro, Lima, Perú), y correos u201714765@upc.edu.pe y u202214784@upc.edu.pe (en adelante, «los Titulares»).')]),
  BloqueLegal.parrafo([TramoLegal('Esta política se rige por la Ley N.° 29733, Ley de Protección de Datos Personales, y su Reglamento, aprobado por el Decreto Supremo N.° 016-2024-JUS, vigente desde el 31 de marzo de 2025.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('2. A quién va dirigida'),
  BloqueLegal.parrafo([TramoLegal('BrillanTEA está dirigida a niñas y niños de 6 a 10 años con TEA, que la usan siempre acompañados por un adulto responsable. La registra y acepta un adulto: la madre, el padre, el tutor o el representante legal, o un cuidador, terapeuta, docente u otro profesional que cuente con su autorización. El niño o niña no ingresa datos personales ni acepta nada por su cuenta.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('3. Qué datos se guardan'),
  BloqueLegal.parrafo([TramoLegal('La aplicación solicita solo los datos necesarios. Todo lo que se indica a continuación se guarda únicamente en este teléfono, salvo las imágenes de la cámara, que no se guardan. Ningún dato se envía a los Titulares.')]),
  BloqueLegal.tarjeta('Nombre, apellido y parentesco del adulto responsable', [[TramoLegal('Para qué: ', negrita: true, acento: true), TramoLegal('Identificar al adulto que registró y acompaña al niño o niña, y verificar su identidad al recuperar el PIN')], [TramoLegal('¿Obligatorio? ', negrita: true, acento: true), TramoLegal('Sí')], [TramoLegal('Si no lo das: ', negrita: true, acento: true), TramoLegal('No se puede crear el perfil')], [TramoLegal('Dónde: ', negrita: true, acento: true), TramoLegal('Solo en este teléfono')]]),
  BloqueLegal.tarjeta('Fecha de nacimiento del adulto responsable', [[TramoLegal('Para qué: ', negrita: true, acento: true), TramoLegal('Confirmar que es mayor de edad')], [TramoLegal('¿Obligatorio? ', negrita: true, acento: true), TramoLegal('Sí')], [TramoLegal('Si no lo das: ', negrita: true, acento: true), TramoLegal('No se puede crear el perfil')], [TramoLegal('Dónde: ', negrita: true, acento: true), TramoLegal('Solo en este teléfono')]]),
  BloqueLegal.tarjeta('Ciudad o distrito del adulto responsable', [[TramoLegal('Para qué: ', negrita: true, acento: true), TramoLegal('Verificar su identidad al recuperar el PIN')], [TramoLegal('¿Obligatorio? ', negrita: true, acento: true), TramoLegal('Sí')], [TramoLegal('Si no lo das: ', negrita: true, acento: true), TramoLegal('No se puede recuperar el PIN con preguntas')], [TramoLegal('Dónde: ', negrita: true, acento: true), TramoLegal('Solo en este teléfono')]]),
  BloqueLegal.tarjeta('Sexo del adulto responsable (femenino, masculino u otro)', [[TramoLegal('Para qué: ', negrita: true, acento: true), TramoLegal('Adaptar el trato en los mensajes de la aplicación')], [TramoLegal('¿Obligatorio? ', negrita: true, acento: true), TramoLegal('No')], [TramoLegal('Si no lo das: ', negrita: true, acento: true), TramoLegal('Se usan mensajes neutros')], [TramoLegal('Dónde: ', negrita: true, acento: true), TramoLegal('Solo en este teléfono')]]),
  BloqueLegal.tarjeta('Nombre, edad y avatar del niño o niña', [[TramoLegal('Para qué: ', negrita: true, acento: true), TramoLegal('Saludarlo por su nombre, adaptar el contenido y mostrar pictogramas de niña o niño')], [TramoLegal('¿Obligatorio? ', negrita: true, acento: true), TramoLegal('Sí')], [TramoLegal('Si no lo das: ', negrita: true, acento: true), TramoLegal('No se puede crear el perfil')], [TramoLegal('Dónde: ', negrita: true, acento: true), TramoLegal('Solo en este teléfono')]]),
  BloqueLegal.tarjeta('PIN del Área de padres', [[TramoLegal('Para qué: ', negrita: true, acento: true), TramoLegal('Proteger el Área de padres')], [TramoLegal('¿Obligatorio? ', negrita: true, acento: true), TramoLegal('Sí, para usar esa área')], [TramoLegal('Si no lo das: ', negrita: true, acento: true), TramoLegal('Sin acceso al Área de padres')], [TramoLegal('Dónde: ', negrita: true, acento: true), TramoLegal('Solo en este teléfono, protegido')]]),
  BloqueLegal.tarjeta('Registro de consentimiento', [[TramoLegal('Para qué: ', negrita: true, acento: true), TramoLegal('Acreditar qué se aceptó y cuándo')], [TramoLegal('¿Obligatorio? ', negrita: true, acento: true), TramoLegal('Sí')], [TramoLegal('Si no lo das: ', negrita: true, acento: true), TramoLegal('No se puede usar la aplicación')], [TramoLegal('Dónde: ', negrita: true, acento: true), TramoLegal('Solo en este teléfono')]]),
  BloqueLegal.tarjeta('Ajustes de accesibilidad y rutinas activas', [[TramoLegal('Para qué: ', negrita: true, acento: true), TramoLegal('Adaptar la aplicación al niño o niña')], [TramoLegal('¿Obligatorio? ', negrita: true, acento: true), TramoLegal('No')], [TramoLegal('Si no lo das: ', negrita: true, acento: true), TramoLegal('Se usan los valores predeterminados')], [TramoLegal('Dónde: ', negrita: true, acento: true), TramoLegal('Solo en este teléfono')]]),
  BloqueLegal.tarjeta('Favoritos', [[TramoLegal('Para qué: ', negrita: true, acento: true), TramoLegal('Accesos directos del niño o niña')], [TramoLegal('¿Obligatorio? ', negrita: true, acento: true), TramoLegal('No')], [TramoLegal('Si no lo das: ', negrita: true, acento: true), TramoLegal('Sin favoritos')], [TramoLegal('Dónde: ', negrita: true, acento: true), TramoLegal('Solo en este teléfono')]]),
  BloqueLegal.tarjeta('Actividad en los módulos', [[TramoLegal('Para qué: ', negrita: true, acento: true), TramoLegal('Seguimiento para el adulto, medallas y pictogramas más usados')], [TramoLegal('¿Obligatorio? ', negrita: true, acento: true), TramoLegal('No, se puede desactivar')], [TramoLegal('Si no lo das: ', negrita: true, acento: true), TramoLegal('Sin seguimiento ni medallas')], [TramoLegal('Dónde: ', negrita: true, acento: true), TramoLegal('Solo en este teléfono')]]),
  BloqueLegal.tarjeta('Emociones elegidas y registro de Calma', [[TramoLegal('Para qué: ', negrita: true, acento: true), TramoLegal('Responder al niño o niña y avisar al adulto')], [TramoLegal('¿Obligatorio? ', negrita: true, acento: true), TramoLegal('No')], [TramoLegal('Si no lo das: ', negrita: true, acento: true), TramoLegal('Sin historial de emociones')], [TramoLegal('Dónde: ', negrita: true, acento: true), TramoLegal('Solo en este teléfono')]]),
  BloqueLegal.tarjeta('Meta y período de premios', [[TramoLegal('Para qué: ', negrita: true, acento: true), TramoLegal('Mostrar el avance en Mis premios')], [TramoLegal('¿Obligatorio? ', negrita: true, acento: true), TramoLegal('No')], [TramoLegal('Si no lo das: ', negrita: true, acento: true), TramoLegal('Premios desactivados')], [TramoLegal('Dónde: ', negrita: true, acento: true), TramoLegal('Solo en este teléfono')]]),
  BloqueLegal.tarjeta('Notas para el especialista', [[TramoLegal('Para qué: ', negrita: true, acento: true), TramoLegal('Apuntes propios del adulto')], [TramoLegal('¿Obligatorio? ', negrita: true, acento: true), TramoLegal('No')], [TramoLegal('Si no lo das: ', negrita: true, acento: true), TramoLegal('Sin notas')], [TramoLegal('Dónde: ', negrita: true, acento: true), TramoLegal('Solo en este teléfono')]]),
  BloqueLegal.tarjeta('Imágenes de la cámara', [[TramoLegal('Para qué: ', negrita: true, acento: true), TramoLegal('Sugerir el pictograma del objeto')], [TramoLegal('¿Obligatorio? ', negrita: true, acento: true), TramoLegal('No, requiere permiso')], [TramoLegal('Si no lo das: ', negrita: true, acento: true), TramoLegal('El módulo Cámara no funciona')], [TramoLegal('Dónde: ', negrita: true, acento: true), TramoLegal('No se guarda: se analiza y se descarta')]]),
  BloqueLegal.parrafo([TramoLegal('Por su relación con el TEA, la actividad del niño o niña, sus emociones y las notas del adulto pueden revelar información sobre su salud. Por ello se tratan como datos sensibles y se solicitan con consentimiento expreso (en la casilla de aceptación).')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('4. Qué guarda cada módulo'),
  BloqueLegal.tarjeta('Cámara', [[TramoLegal('Guarda: ', negrita: true, acento: true), TramoLegal('Nada. La imagen se analiza en el momento y se descarta.')], [TramoLegal('No guarda: ', negrita: true, acento: true), TramoLegal('Fotos, videos ni ubicación.')]]),
  BloqueLegal.tarjeta('Comunicación', [[TramoLegal('Guarda: ', negrita: true, acento: true), TramoLegal('Pictogramas y frases más usados (para Seguimiento y Favoritos).')], [TramoLegal('No guarda: ', negrita: true, acento: true), TramoLegal('Grabaciones de voz.')]]),
  BloqueLegal.tarjeta('Vocabulario', [[TramoLegal('Guarda: ', negrita: true, acento: true), TramoLegal('Palabras marcadas como favoritas.')], [TramoLegal('No guarda: ', negrita: true, acento: true), TramoLegal('Respuestas evaluadas ni calificaciones.')]]),
  BloqueLegal.tarjeta('Rutinas', [[TramoLegal('Guarda: ', negrita: true, acento: true), TramoLegal('Rutinas completadas, medallas y rutinas activas.')], [TramoLegal('No guarda: ', negrita: true, acento: true), TramoLegal('Fotos del niño o niña realizando la rutina.')]]),
  BloqueLegal.tarjeta('Emociones', [[TramoLegal('Guarda: ', negrita: true, acento: true), TramoLegal('Emoción elegida y cuántas veces se eligió (emoción frecuente).')], [TramoLegal('No guarda: ', negrita: true, acento: true), TramoLegal('Diagnósticos ni interpretaciones clínicas.')]]),
  BloqueLegal.tarjeta('Situaciones', [[TramoLegal('Guarda: ', negrita: true, acento: true), TramoLegal('Situaciones vistas.')], [TramoLegal('No guarda: ', negrita: true, acento: true), TramoLegal('Lugares reales ni ubicación.')]]),
  BloqueLegal.tarjeta('Calma', [[TramoLegal('Guarda: ', negrita: true, acento: true), TramoLegal('Cómo se sentía, qué ejercicio intentó y si mejoró, para el aviso al adulto.')], [TramoLegal('No guarda: ', negrita: true, acento: true), TramoLegal('Audio, video ni datos de salud del teléfono.')]]),
  BloqueLegal.tarjeta('Área de padres', [[TramoLegal('Guarda: ', negrita: true, acento: true), TramoLegal('Ajustes, premios, notas y registro de consentimiento.')], [TramoLegal('No guarda: ', negrita: true, acento: true), TramoLegal('Contraseñas de otras cuentas ni datos de pago.')]]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('5. Qué datos no se solicitan'),
  BloqueLegal.parrafo([TramoLegal('La aplicación no solicita segundos nombres ni segundos apellidos, el apellido ni la fecha de nacimiento del niño o niña, alias ni sobrenombres, dirección, documentos de identidad, diagnóstico, fotos ni grabaciones de voz del menor, ubicación del teléfono ni contactos.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('6. Finalidades y base legal'),
  BloqueLegal.parrafo([TramoLegal('6.1.', negrita: true, acento: true), TramoLegal(' Los datos se usan para que la aplicación funcione, adaptar los módulos al niño o niña, mostrar al adulto el seguimiento, las medallas y los avisos de Calma, proteger el Área de padres y acreditar el consentimiento.')]),
  BloqueLegal.parrafo([TramoLegal('6.2.', negrita: true, acento: true), TramoLegal(' No se usan para publicidad, perfiles comerciales, venta de datos ni decisiones automatizadas sobre el menor.')]),
  BloqueLegal.parrafo([TramoLegal('6.3.', negrita: true, acento: true), TramoLegal(' La base legal es el consentimiento previo, libre, expreso, inequívoco e informado del representante legal del menor o de quien cuente con su autorización. La casilla de aceptación incluye de forma expresa la autorización para tratar los datos sensibles. El consentimiento puede retirarse en cualquier momento en Área de padres → Retirar consentimiento.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('7. Funciones que operan en el teléfono'),
  BloqueLegal.parrafo([TramoLegal('7.1.', negrita: true, acento: true), TramoLegal(' Cámara: un modelo de reconocimiento de objetos funciona en el propio teléfono. Antes de solicitar el permiso de cámara, la aplicación explica para qué se usa.')]),
  BloqueLegal.parrafo([TramoLegal('7.2.', negrita: true, acento: true), TramoLegal(' Voz: la lectura en voz alta usa el sistema de voz de Android. La aplicación no graba audio. Algunas voces de Android pueden requerir internet; se recomienda usar voces instaladas en el teléfono.')]),
  BloqueLegal.parrafo([TramoLegal('7.3.', negrita: true, acento: true), TramoLegal(' Aviso de Calma: cuando el niño o niña toca «Pedir ayuda», la aplicación muestra al adulto qué sintió y qué intentó.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('8. Con quién se comparten'),
  BloqueLegal.parrafo([TramoLegal('8.1.', negrita: true, acento: true), TramoLegal(' La aplicación no comparte datos con nadie. Los Titulares no tienen acceso a la información guardada en el teléfono.')]),
  BloqueLegal.parrafo([TramoLegal('8.2.', negrita: true, acento: true), TramoLegal(' Si el adulto descarga o comparte el reporte de Seguimiento, decide dónde se guarda y con quién lo comparte; el archivo queda fuera de la aplicación.')]),
  BloqueLegal.parrafo([TramoLegal('8.3.', negrita: true, acento: true), TramoLegal(' Si el adulto activa las copias de seguridad de Android, Google trata esa copia según sus propias condiciones.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('9. Conservación y eliminación'),
  BloqueLegal.parrafo([TramoLegal('9.1.', negrita: true, acento: true), TramoLegal(' Los datos se conservan mientras exista el perfil. En Área de padres → Borrar los datos se pueden borrar todos los datos del dispositivo. El borrado es inmediato y no se puede deshacer.')]),
  BloqueLegal.parrafo([TramoLegal('9.2.', negrita: true, acento: true), TramoLegal(' Al desinstalar la aplicación, Android elimina sus datos, salvo las copias de seguridad activadas y los reportes descargados.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('10. Derechos y plazos de respuesta'),
  BloqueLegal.parrafo([TramoLegal('10.1.', negrita: true, acento: true), TramoLegal(' El representante legal del menor, o el adulto responsable autorizado, puede ejercer los derechos de información, acceso, rectificación, cancelación y oposición, y los demás que reconoce la ley.')]),
  BloqueLegal.parrafo([TramoLegal('10.2.', negrita: true, acento: true), TramoLegal(' Como los datos solo están en este teléfono, estos derechos se ejercen en la propia aplicación: ver los datos en Perfil del menor y Seguimiento, corregir los del niño o niña en Perfil del menor, y borrarlos o retirar el consentimiento en Área de padres. Para cualquier consulta o solicitud, puede escribir a u201714765@upc.edu.pe o u202214784@upc.edu.pe con el asunto «Derechos sobre datos personales».')]),
  BloqueLegal.parrafo([TramoLegal('10.3.', negrita: true, acento: true), TramoLegal(' Los Titulares responderán en los plazos de la normativa, contados en días hábiles desde el día siguiente a la recepción de la solicitud: información, 8 días; acceso, 20 días; rectificación, cancelación y oposición, 10 días. Salvo el de información, estos plazos pueden ampliarse por única vez por un período igual cuando las circunstancias lo justifiquen, lo que se comunicará al solicitante.')]),
  BloqueLegal.parrafo([TramoLegal('10.4.', negrita: true, acento: true), TramoLegal(' Si la solicitud no es atendida, puede presentarse un reclamo ante la Autoridad Nacional de Protección de Datos Personales.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('11. Seguridad'),
  BloqueLegal.parrafo([TramoLegal('11.1.', negrita: true, acento: true), TramoLegal(' Medidas aplicadas: datos guardados solo en el teléfono, solicitud del mínimo de datos necesarios, PIN con bloqueo de cinco minutos tras tres intentos fallidos, ausencia de analítica y publicidad, y revisión de las librerías de la aplicación.')]),
  BloqueLegal.parrafo([TramoLegal('11.2.', negrita: true, acento: true), TramoLegal(' El adulto también contribuye a la seguridad al usar bloqueo de pantalla, mantener Android actualizado y elegir un PIN difícil de adivinar.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('12. Incidentes de seguridad'),
  BloqueLegal.parrafo([TramoLegal('Si los Titulares detectan un incidente de seguridad que afecte datos bajo su control (por ejemplo, una versión de la aplicación comprometida), lo comunicarán a la Autoridad Nacional de Protección de Datos Personales dentro del plazo legal e informarán a las personas afectadas.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('13. Registro ante la Autoridad'),
  BloqueLegal.parrafo([TramoLegal('Los Titulares cumplirán, cuando corresponda, con la inscripción del banco de datos personales y con la designación de un oficial de datos personales.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('14. Cambios en esta política'),
  BloqueLegal.parrafo([TramoLegal('Cualquier cambio se informará dentro de la aplicación junto con la fecha de la nueva versión. Si cambian los datos que se guardan o sus finalidades, se solicitará nuevamente el consentimiento.')]),
  BloqueLegal.espacio(),
  BloqueLegal.titulo('15. Contacto y atribuciones'),
  BloqueLegal.parrafo([TramoLegal('Ayuda y soporte en la aplicación · u201714765@upc.edu.pe · u202214784@upc.edu.pe · Campus San Isidro de la UPC (Av. Salaverry 2255, San Isidro, Lima, Perú).')]),
  BloqueLegal.parrafo([TramoLegal('Pictogramas: ARASAAC (https://arasaac.org), autor Sergio Palao, propiedad del Gobierno de Aragón, licencia CC BY-NC-SA 4.0.')]),
  BloqueLegal.divisor(),
  BloqueLegal.pie('Fin del documento · Versión 1.0'),
];
