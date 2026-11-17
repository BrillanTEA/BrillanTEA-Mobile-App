# Casos de prueba

Versión de la app: 0.2.0-alpha.1+14. Los casos automatizados se ejecutan con `flutter test`
(o `bash tool/qa.sh`); los manuales, en un celular Android según el [plan](PLAN_DE_PRUEBAS.md).

## Automatizados

| ID | Requisito | Archivo | Precondición | Pasos | Resultado esperado |
|---|---|---|---|---|---|
| CP-01 | RF-02, OE2-I3 | `catalogo_test.dart` | Catálogo empaquetado en `assets/catalogo.json`. | Ejecutar `flutter test`. | Hay 35 objetos con clave única y 5 rutinas; cada objeto y cada paso tiene nombre, frase y un pictograma que existe en los assets. |
| CP-02 | RF-03, OE3-I3 | `catalogo_test.dart` | Catálogo y rutinas de la app cargados. | Ejecutar `flutter test`. | «Ir a rutina» solo aparece con el objeto del primer paso de cada rutina; Ir a comer no tiene objeto de inicio. |
| CP-03 | RF-02 | `perfil_yolo26_test.dart` | Modelo y archivo de etiquetas del candidato aprobado. | Ejecutar `flutter test`. | Las 35 etiquetas siguen el orden de IDs del catálogo; se rechazan etiquetas COCO, faltantes o reordenadas, la salida de una exportación errónea y las puntuaciones no finitas. |
| CP-04 | RF-19 | `catalogo_test.dart` | — | Ejecutar `flutter test`. | El período de medallas empieza hoy (diario), el lunes (semanal) o el día 1 (mensual); las metas van de 1 a 5 por día, de 10 a 35 por semana y de 20 a 100 por mes, se pueden lograr con las 5 rutinas, y una meta fuera de rango da el mensaje del diseño. |
| CP-05 | RF-06 | `pin_input_cuadros_test.dart`, `formatters_test.dart` | — | Ejecutar `flutter test`. | El PIN se ingresa en 4 casillas con escritura y borrado; los datos de recuperación se comparan sin tildes y conservan la ñ. |
| CP-06 | RF-16 | `accesibilidad_test.dart` | — | Ejecutar `flutter test`. | Al cambiar el tamaño de texto en Accesibilidad, cambia la escala del texto de la aplicación. |
| CP-24 | RF-06, RF-08 | `base_datos_migration_test.dart` | Base de datos de una versión anterior. | Ejecutar `flutter test`. | La migración a la versión 8 conserva los datos, agrega el período de premios y la versión aceptada de los documentos; una instalación nueva registra la versión y la fecha de aceptación. |
| CP-25 | RF-05, RF-12 | `comunicacion_test.dart` | — | Ejecutar `flutter test`. | Se arman las frases del diseño («Yo quiero agua», «A mí me gusta jugar con peluches», «Yo no quiero pollo», «Yo necesito ayuda», «A mí me duele la cabeza»); Baño y Ayuda terminan en el paso 2; las preguntas cambian según el verbo y la categoría; cada pictograma existe en los assets. |
| CP-26 | RF-09, RF-11 | `vocabulario_emociones_test.dart` | — | Ejecutar `flutter test`. | Las categorías tienen los elementos del diseño (animales 25, colores 8, números 100, letras 27, frutas 15, formas 11) con id único e imagen empaquetada; hay 8 emociones en orden y todas, menos Alegre, tienen respuesta para niño y niña. |
| CP-27 | RF-20 | `tutoriales_test.dart` | — | Ejecutar `flutter test`. | Los seis módulos con tutorial por pasos (cámara, comunicación, vocabulario, rutinas, emociones y calma) tienen 5 pasos y 3 consejos, con su captura empaquetada; Situaciones conserva su tutorial de detalle. |
| CP-28 | RF-06, RF-17 | `documentos_legales_test.dart` | — | Ejecutar `flutter test`. | Los Términos y la Política muestran una sola versión (1.0), describen una casilla y la sección Privacidad y datos, y usan los mismos correos de soporte que la app. |

## Manuales

| ID | Requisito | Precondición | Pasos y entradas | Resultado esperado |
|---|---|---|---|---|
| CP-07 | RF-01, RF-02, OE3-I2 | App instalada y permiso de cámara concedido. | Apuntar a cada uno de los 35 objetos a 3 distancias, con 2 iluminaciones y desde 3 ángulos (630 pruebas). | Junto a cada objeto reconocido aparece su tarjeta con el pictograma (como máximo 2 a la vez); la exhaustividad es de al menos 80 %. |
| CP-08 | RF-03 | Rutina Lavado de manos activa. | Apuntar al caño y tocar su tarjeta. | Se abre el pictograma ampliado con su frase y Escuchar, y el botón «Ir a rutina» lleva a Lavado de manos. |
| CP-09 | RF-04, RF-19 | Premios activados. | Iniciar Lavado de manos y tocar «¡Terminé!» en cada paso hasta el final. | Cada paso muestra AHORA y DESPUÉS; el temporizador muestra «¡Listo!» y espera el toque; al final aparece el mensaje de felicitación y se suma una medalla. |
| CP-10 | RF-05 | Modo avión activado. | En Pedir algo, elegir la categoría Comer y luego Pan. | La frase predefinida se reproduce en voz sin conexión y la petición queda registrada. |
| CP-11 | RF-12 | — | En Armar frase, elegir «me gusta», una categoría y un pictograma. | La primera tarjeta cambia de «Yo» a «A mí» y la aplicación dice «A mí me gusta…» y ofrece repetirla o armar otra. |
| CP-12 | RF-13 | — | En Responder, tocar Sí y luego No. | Cada respuesta se dice en voz. |
| CP-13 | RF-11 | Perfil del niño con avatar de niña. | Tocar la emoción Enojado tres veces en menos de un minuto. | La aplicación dice «Me siento enojada» y la emoción se registra una sola vez. |
| CP-14 | RF-14 | — | Elegir Ir al doctor y avanzar con Siguiente y Anterior. | Cada paso se escucha; al final aparece «Muy bien» con Leer otra vez. |
| CP-15 | RF-18 | — | En Calma, hacer el ejercicio de respirar y responder «Igual»; luego pedir ayuda. | La aplicación muestra un aviso para el adulto. |
| CP-16 | RF-10 | Tres pictogramas marcados como favoritos. | Usar uno de ellos varias veces y volver a Favoritos. | El favorito más usado aparece primero; si dos empatan, aparece primero el más antiguo. |
| CP-17 | RF-06, RF-08 | PIN registrado. | Ingresar tres PIN incorrectos en el área de padres. | El ingreso se bloquea 5 minutos con un contador y no se accede al área de padres. |
| CP-18 | RF-06 | PIN registrado. | Tocar «¿Olvidaste tu PIN?» y responder el año de nacimiento, el apellido materno y la ciudad de nacimiento, con y sin tildes. | La aplicación permite crear un PIN nuevo. |
| CP-19 | RF-08 | Datos registrados (perfiles, favoritos y progreso). | En Área de padres > Privacidad y datos, tocar «Borrar los datos» e ingresar el PIN; repetir con un PIN incorrecto. | Con el PIN correcto se borran todos los datos y la app vuelve a la bienvenida; con el incorrecto no se borra nada. |
| CP-20 | RF-15, RNF-04 | Uso registrado durante la semana. | En Seguimiento, tocar Exportar y confirmar. | Se muestra qué datos contiene el reporte; el PDF incluye solo el primer nombre o apodo, la edad y las métricas, se abre la hoja de compartir y la copia temporal se elimina después. |
| CP-21 | RF-07 | Bloqueo de pantalla del celular configurado. | Fijar la pantalla e intentar salir de la aplicación. | Para salir, Android pide el PIN del celular. |
| CP-22 | RNF-02 | Modo avión activado. | Recorrer los siete módulos y el área de padres. | Todas las funciones operan sin conexión. |
| CP-23 | RNF-05 | — | Compilar la versión oficial y la versión QA y revisar el APK y los menús. | El APK pesa como máximo 100 MB; la versión oficial no muestra opciones de restablecimiento ni el panel técnico y la versión QA sí. |
| CP-29 | RF-06 | App recién instalada. | En el primer uso, intentar continuar sin marcar la casilla; abrir los Términos y la Política; marcar la casilla y continuar. Luego ir a Área de padres > Privacidad y datos. | Sin la casilla no se puede continuar; los dos documentos se abren desde el registro. En Privacidad y datos, «Consentimiento otorgado» muestra la fecha y hora de aceptación y la versión 1.0. |
| CP-30 | RF-08 | Datos registrados. | En Privacidad y datos, tocar «Retirar consentimiento», leer el aviso e ingresar el PIN. | El aviso explica que se borrarán los datos; con el PIN correcto se borran y la app vuelve a la bienvenida para aceptar de nuevo. |
| CP-31 | RF-19 | Premios activados. | En Área de padres > Premios, elegir el período Diaria y escribir 8; luego escribir 3 y guardar. | Con 8 aparece el mensaje de rango (de 1 a 5 por día) y no se guarda; con 3 aparece la confirmación y el niño ve sus medallas del día. |
| CP-32 | RF-20 | — | En Área de padres > Tutoriales, abrir el de la Cámara y avanzar con Siguiente y Anterior. | Se recorren 7 pantallas con capturas de la app y lectura en voz; «Terminar» vuelve a la lista de tutoriales. |
| CP-33 | RF-08 | Rutinas configuradas. | Editar las rutinas activas de una categoría, tocar Atrás sin guardar y elegir Descartar; repetir eligiendo Guardar. | Aparece el diálogo de confirmación; con Descartar no cambia nada y con Guardar se aplican los cambios. |
| CP-34 | RF-17 | App de correo instalada. | En Ayuda y soporte, tocar «Escribir a soporte». | Se abre la app de correo con los dos destinatarios de soporte y el asunto. |
