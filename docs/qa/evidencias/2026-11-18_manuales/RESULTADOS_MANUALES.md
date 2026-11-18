# Resultados de pruebas manuales y capturas para la Memoria

## Datos de ejecución

- **Fecha:** 2026-11-18
- **Modelo del celular:** Samsung `SM-A256E` (Galaxy A25)
- **Versión de Android:** Android 16
- **Commit:** `6b7b536` (rama `develop`)
- **Versión de la app (`pubspec.yaml`):** `0.2.0-alpha.1+14`
- **Paquete:** `pe.brillantea.app`
- **Carpeta de evidencias:** `docs/qa/evidencias/2026-11-18_manuales/`

---

## Ejecución de casos manuales (`capturas_casos/`)

| ID | Ejecutado por | Pasos realmente hechos | Resultado obtenido | Estado | Capturas |
|---|---|---|---|---|---|
| CP-07 | Ricardo | — | A cargo de Ricardo (módulo Cámara). | A cargo de Ricardo | — |
| CP-08 | Ricardo | — | A cargo de Ricardo (módulo Cámara / «Ir a rutina»). | A cargo de Ricardo | — |
| CP-09 | Antigravity | En `Rutinas`, se inició `Lavado de manos`; se avanzó cada paso con `¡Terminé!` pasando por `AHORA`/`DESPUÉS` y el temporizador hasta `¡Listo!`, llegando a la felicitación final. | Cada paso mostró `AHORA` y `DESPUÉS`; el temporizador llegó a `¡Listo!` esperando toque; al finalizar apareció el mensaje de felicitación y se sumó la medalla. | Aprobado | `CP-09_01_lista_rutinas.png`, `CP-09_02_paso1_ahora_despues.png`, `CP-09_03_temporizador_listo.png`, `CP-09_04_felicitacion_medalla.png` |
| CP-10 | Antigravity | Se activó modo avión por ADB (`airplane_mode_on=1`, aunque el Wi-Fi permaneció activo para conservar la depuración inalámbrica). En `Comunicación > Pedir algo > Comer` se tocó `Quiero pan` y luego se revisó `Seguimiento`. | En pantalla se seleccionó `Quiero pan` y en `Seguimiento` aumentó el contador semanal de peticiones con pictogramas (`+3 peticiones con pictogramas`). No se pudo verificar por audio si el TTS se escuchó ni operar con Wi-Fi totalmente apagado. | Requiere verificación humana | `CP-10_01_modo_avion_comer.png`, `CP-10_02_pan_seleccionado.png` |
| CP-11 | Antigravity | En `Comunicación > Armar mi frase`, se eligió `me gusta`, una categoría y un pictograma. | En pantalla la primera tarjeta cambió de `Yo` a `A mí` y se formó la frase (`A mí me gusta…`) con opciones para repetir o armar otra. Falta verificar auditivamente que la voz TTS la pronuncia correctamente. | Requiere verificación humana | `CP-11_01_armar_frase_inicio.png`, `CP-11_02_me_gusta_a_mi.png`, `CP-11_03_frase_completa.png` |
| CP-12 | Antigravity | En `Comunicación > Responder`, se tocó `Sí` y luego `No`. | Se observó la respuesta visual en pantalla al tocar `Sí` y `No`. Falta verificar auditivamente la lectura en voz de cada respuesta. | Requiere verificación humana | `CP-12_01_responder_inicial.png`, `CP-12_02_toco_si.png`, `CP-12_03_toco_no.png` |
| CP-13 | Antigravity | Con el perfil de `Ana` (avatar `Niña`), se tocó la emoción `Enojado` 3 veces en menos de un minuto y se revisó `Seguimiento`. | En UI se mostró la adaptación femenina (`enojada`) y en `Seguimiento` se registró una sola vez (`1`). Falta verificar auditivamente que la app dice «Me siento enojada». | Requiere verificación humana | `CP-13_01_emociones_inicial.png`, `CP-13_02_enojado_tap1.png`, `CP-13_03_enojado_tap3.png`, `CP-13_04_seguimiento_conteo_1.png` |
| CP-14 | Antigravity | En `Situaciones`, se abrió `Ir al doctor` y se recorrieron los pasos con `Siguiente` y `Anterior` hasta el final. | Se recorrieron los pasos y al final apareció `Muy bien` con el botón `Leer otra vez`. Falta verificar auditivamente la locución de cada paso. | Requiere verificación humana | `CP-14_01_situaciones_lista.png`, `CP-14_02_paso1.png`, `CP-14_03_paso2.png`, `CP-14_04_final_muy_bien.png` |
| CP-15 | Antigravity | En `Calma`, se completó el ejercicio de respirar, se respondió `Igual` ante `¿Cómo te sientes?` y luego se solicitó ayuda. | La app mostró la pantalla y el detalle del aviso dirigido al adulto. | Aprobado | `CP-15_01_calma_inicio.png`, `CP-15_02_respirar.png`, `CP-15_03_como_te_sientes.png`, `CP-15_04_respuesta_igual.png`, `CP-15_05_aviso_adulto.png`, `CP-15_06_aviso_adulto_detalle.png` |
| CP-16 | Antigravity | En `Vocabulario > Animales`, se marcaron 3 pictogramas como favoritos, se abrió `Favoritos`, se usó uno de ellos varias veces y se volvió a `Favoritos` (y luego se reinició la app para comprobar persistencia). | Al volver a la pestaña `Favoritos` dentro de la misma sesión, el favorito más usado **no** pasó al primer lugar (`CP-16_04_favoritos_despues_uso.png`). Recién al reiniciar la app (`CP-16_05_favoritos_tras_reinicio.png`) apareció ordenado por uso. | Fallido | `CP-16_01_vocabulario_animales.png`, `CP-16_02_tres_favoritos_marcados.png`, `CP-16_03_favoritos_inicial.png`, `CP-16_04_favoritos_despues_uso.png`, `CP-16_05_favoritos_tras_reinicio.png` |
| CP-17 | Antigravity | En `Área para padres`, se ingresaron 3 PIN incorrectos (`0000`), se esperaron los 5 minutos completos del contador y luego se ingresó el PIN correcto (`1357`). | Tras el tercer fallo se mostró `Opción bloqueada` con contador de 5 minutos (`04:55` visible en captura). Al llegar a `00:00` regresó automáticamente a `Área para padres` y con `1357` permitió entrar a `Seguimiento`. *(Ver observación de texto en Defectos).* | Aprobado | `CP-17_01_pin_bloqueado_5min.png`, `CP-17_02_bloqueo_terminado.png`, `CP-17_03_acceso_restaurado.png` |
| CP-18 | Antigravity | Se tocó `¿Olvidaste tu PIN?`; primero se respondió `maria` / `perez` / `cercado de lima` (sin tildes, limitación de `adb shell input text` ASCII) y se guardó el PIN `1357`; luego se fallaron 3 intentos (`uno`/`dos`/`tres`). | Con respuestas sin tildes verificó identidad, permitió crear PIN (`¡PIN guardado!`) y al tercer fallo bloqueó la opción 5 minutos (`04:56` visible). Falta probar con teclado real del celular el ingreso con tildes (`María`, `Pérez`). *(Ver observación en Defectos).* | Requiere verificación humana | `CP-18_01_recuperacion_preguntas.png`, `CP-18_02_crear_nuevo_pin.png`, `CP-18_03_pin_guardado.png`, `CP-18_04_recuperacion_bloqueada_5min.png` |
| CP-19 | Antigravity | Con perfiles (`Maria Perez`, `Ana`), favorito (`PERRO`) y uso registrados, en `Privacidad y datos > Borrar los datos` se ingresó primero PIN incorrecto (`0000`) y luego PIN correcto (`1357`). | Con `0000` mostró `PIN incorrecto.` y mantuvo los datos intactos; con `1357` eliminó todos los datos y volvió a la pantalla de bienvenida (`¡Hola!`). | Aprobado | `CP-19_01_pin_incorrecto.png`, `CP-19_02_datos_borrados_bienvenida.png` |
| CP-20 | Antigravity | En `Seguimiento`, se tocó exportar/descargar reporte, se revisó el diálogo informativo y se confirmó para abrir la hoja de compartir de Android, volviendo atrás sin compartir. | Se mostró qué datos incluye el reporte y se abrió la hoja de compartir del sistema. No se abrió el PDF generado para verificar su contenido interno ni se comprobó la eliminación de la copia temporal tras volver. | Requiere verificación humana | `CP-20_01_seguimiento_abajo.png`, `CP-20_02_reporte_contenido.png`, `CP-20_03_hoja_compartir.png`, `CP-20_04_tras_volver_de_compartir.png` |
| CP-21 | Antigravity y Ricardo | Con «Fijar aplicación» y «Solicitar PIN antes de desfijar» habilitados por Ricardo en Ajustes, se verificó la app fijada (`mLockTaskModeState=PINNED`), se intentó salir con `KEYCODE_APP_SWITCH`, Ricardo desfijó manualmente ingresando su PIN del celular (`mLockTaskModeState=NONE`), y en `Área de padres > Accesibilidad` se activó `Fijar pantalla (Modo seguro)`. | No se pudo salir con `KEYCODE_APP_SWITCH`; en `Accesibilidad` se mostró el aviso de pantalla fijada. Ricardo comprobó en vivo el diálogo de 2 botones y el pedido de PIN del celular para salir, pero no existe captura del aviso del PIN del sistema operativo. | Requiere verificación humana | `CP-21_01_intento_salir_fijada.png`, `CP-21_02_aviso_fijar_pantalla.png` |
| CP-22 | Antigravity | Con `airplane_mode_on=1` (manteniendo Wi-Fi activo únicamente para conservar la conexión ADB), se recorrieron los módulos de `Comunicación`, `Vocabulario`, `Rutinas`, `Emociones`, `Situaciones`, `Calma`, `Favoritos` y `Área de padres > Seguimiento`. Al terminar se desactivó el modo avión. | Todas las secciones recorridas operaron sin errores con `airplane_mode_on=1`. Queda pendiente verificar sin Wi-Fi encendido (desconexión total de red) y el módulo `Cámara`. | Requiere verificación humana | `CP-22_01_comunicacion.png`, `CP-22_02_vocabulario.png`, `CP-22_03_rutinas.png`, `CP-22_04_emociones.png`, `CP-22_05_situaciones.png`, `CP-22_06_calma.png`, `CP-22_07_favoritos.png`, `CP-22_08_area_padres_seguimiento.png` |
| CP-23 | Antigravity | Se compilaron la versión oficial (`QA=false`) y la versión QA (`QA=true`), se compararon tamaños (`ls -l`), se instaló la QA para capturar el menú lateral de `Inicio` y se reinstaló la oficial para capturar el mismo menú. | Todos los APKs pesaron menos de 100 MB (oficial arm64-v8a: `83,225,517` B / 79 MiB; armeabi-v7a: `78,464,817` B / 75 MiB; x86_64: `86,842,445` B / 83 MiB; QA arm64-v8a: `83,488,357` B / 80 MiB; armeabi-v7a: `78,744,041` B / 75 MiB; x86_64: `87,105,285` B / 83 MiB). El menú QA mostró `Restablecer onboarding (QA)` y el oficial no. Falta que Ricardo verifique el panel técnico dentro de `Cámara`. | Requiere verificación humana | `CP-23_01_qa_menu.png`, `CP-23_02_oficial_menu.png` |
| CP-29 | Antigravity | Tras `pm clear pe.brillantea.app`, en el primer uso se verificó `Continuar` sin casilla, se abrieron `Términos y condiciones` y `Política de privacidad`, se marcó la casilla, se completó el registro y se abrió `Área de padres > Privacidad y datos`. | Sin marcar la casilla no dejó continuar; ambos documentos se abrieron desde el registro; en `Privacidad y datos`, `Consentimiento otorgado` mostró la fecha, hora de aceptación y `Versión 1.0`. | Aprobado | `CP-29_01_bienvenida.png`, `CP-29_02_terminos_sin_casilla.png`, `CP-29_03_terminos_abierto.png`, `CP-29_04_politica_abierta.png`, `CP-29_05_casilla_marcada.png`, `CP-29_06_privacidad_y_datos.png` |
| CP-30 | Antigravity | En `Área de padres > Privacidad y datos`, se tocó `Retirar consentimiento`, se leyó el diálogo y se ingresó el PIN `1357` para confirmar. | El aviso explicó que la app dejaría de usar los datos del menor y borraría todo lo guardado volviendo al inicio; al confirmar con `1357`, borró los datos y regresó a `¡Hola!`. | Aprobado | `CP-30_01_aviso_retirar.png`, `CP-30_02_vuelta_bienvenida.png` |
| CP-31 | Antigravity | En `Área de padres > Premios`, se seleccionó `Diaria`, se probó la meta `8`, luego la meta `3`, se guardó y se abrió `Ver mis premios` del niño. | Con `8` mostró el mensaje de rango válido (`1 a 5 por día`) y no guardó; con `3` mostró confirmación y `Ver mis premios` reflejó las medallas del día. | Aprobado | `CP-31_01_premios_inicial.png`, `CP-31_02_diaria_meta_8_invalida.png`, `CP-31_03_diaria_meta_3.png`, `CP-31_04_guardado_confirmacion.png`, `CP-31_05_meta_guardada.png`, `CP-31_06_mis_premios_diaria.png` |
| CP-32 | Antigravity | En `Área de padres > Tutoriales`, se abrió el tutorial de la `Cámara` y se recorrieron sus 7 pantallas con `Siguiente` y `Anterior` hasta `Terminar`. | Se mostraron las 7 pantallas con capturas de la app y `Terminar` regresó a la lista de tutoriales. Falta verificar auditivamente la lectura en voz. | Requiere verificación humana | `CP-32_01_tutoriales_lista.png`, `CP-32_02_camara_paso1.png`, `CP-32_03_camara_paso2_con_captura.png`, `CP-32_04_pantalla7_consejos.png`, `CP-32_05_vuelve_a_lista.png` |
| CP-33 | Antigravity | En configuración de rutinas, se desactivó una rutina en una categoría (`Higiene`), se tocó `Atrás` sin guardar y se eligió `Descartar`; luego se repitió el cambio y se eligió `Guardar`. | Apareció el diálogo de confirmación; con `Descartar` no cambió nada y con `Guardar` aplicó `1 de 2` activas. *(Ver observación menor en Defectos).* | Aprobado | `CP-33_01_rutinas_activas_inicial.png`, `CP-33_02_editado_sin_guardar.png`, `CP-33_03_dialogo_descartar.png`, `CP-33_04_descartado_sin_cambios.png`, `CP-33_05_despues_confirmar.png`, `CP-33_06_guardado_1_de_2.png` |
| CP-34 | Antigravity | En `Área de padres > Ayuda y soporte`, se tocó `Escribir a soporte`, se eligió la app de correo y se volvió atrás sin enviar. | Se abrió la app de correo con los destinatarios `u201714765@upc.edu.pe, u202214784@upc.edu.pe` y el asunto precargados. | Aprobado | `CP-34_01_ayuda_soporte.png`, `CP-34_02_selector_correo.png`, `CP-34_03_correo_soporte.png` |

---

## Capturas para la Memoria (`capturas_memoria/`)

1. `01_bienvenida_terminos.png` — Pantalla de Términos y privacidad en el primer uso con la casilla de consentimiento.
2. `02_inicio.png` — Pantalla `Inicio` con los 7 módulos disponibles para el menor.
3. `03_rutinas_lista.png` — Lista de rutinas disponibles dentro del módulo `Rutinas`.
4. `04_rutina_paso_ahora_despues.png` — Vista de un paso de rutina con tarjetas `AHORA` y `DESPUÉS`.
5. `05_rutina_temporizador.png` — Pantalla de temporizador activo durante un paso de rutina.
6. `06_rutina_medalla.png` — Pantalla final de felicitación con medalla al completar la rutina.
7. `07_pedir_algo_categoria.png` — Selector de categorías del flujo `Pedir algo` en `Comunicación`.
8. `08_pedir_algo_pictograma.png` — Cuadrícula de pictogramas dentro de una categoría de `Pedir algo`.
9. `09_armar_frase.png` — Pantalla de `Armar mi frase` mostrando la frase construida en tres pasos.
10. `10_responder_si_no.png` — Pantalla de `Responder` con los botones `Sí` y `No`.
11. `11_emociones.png` — Cuadrícula con las emociones disponibles en `Emociones`.
12. `12_situaciones_paso.png` — Paso ilustrado de una historia social en `Situaciones`.
13. `13_situaciones_final.png` — Pantalla final `Muy bien` de `Situaciones` con `Leer otra vez`.
14. `14_calma_respirar.png` — Ejercicio guiado de respiración en `Calma`.
15. `15_calma_aviso_adulto.png` — Aviso dirigido al adulto tras responder `Igual` y pedir ayuda en `Calma`.
16. `16_vocabulario_favoritos.png` — Pestaña `Favoritos` mostrando pictogramas marcados desde `Vocabulario`.
17. `17_premios_nino.png` — Vista de premios y medallas del niño o niña (`Ver mis premios`).
18. `18_area_padres_pin.png` — Pantalla de ingreso de PIN del `Área para padres` con dos dígitos escritos y sin teclado tapando `Continuar`.
19. `19_area_padres_menu.png` — Menú principal del `Área de padres` con sus secciones de administración.
20. `20_padres_premios.png` — Pantalla de configuración de período y meta de medallas en `Área de padres > Premios`.
21. `21_padres_rutinas.png` — Pantalla de gestión de rutinas activas en `Área de padres`.
22. `22_tutoriales_lista.png` — Lista de tutoriales disponibles en `Área de padres > Tutoriales`.
23. `23_tutorial_paso.png` — Pantalla de detalle de un paso del tutorial con captura de la app.
24. `24_seguimiento.png` — Resumen de actividad semanal, comparativa y pictogramas más usados en `Seguimiento`.
25. `25_reporte_contenido.png` — Diálogo previo a la descarga que explica qué contiene el reporte PDF.
26. `26_reporte_pdf_compartir.png` — Hoja de compartir de Android abierta con el reporte PDF generado.
27. `27_privacidad_datos.png` — Pantalla `Privacidad y datos` con documentos, consentimiento (`Versión 1.0`) y opciones de borrado.
28. `28_ayuda_soporte.png` — Pantalla `Ayuda y soporte` con preguntas frecuentes y contacto de soporte.
29. `29_fijar_pantalla.png` — Pantalla de `Accesibilidad` al activar `Fijar pantalla (Modo seguro)` mostrando el aviso de pantalla fijada.

---

## Defectos encontrados

### 1. `CP-16` — `Favoritos` no se reordena por uso dentro de la misma sesión al regresar a la pestaña
- **Severidad:** Media (funcional)
- **Descripción:** Al usar un pictograma marcado como favorito varias veces y volver a la pestaña `Favoritos` sin cerrar la app, la lista mantiene el orden previo en lugar de mover el más usado al primer lugar. El ordenamiento por uso recién se refleja tras reiniciar la aplicación (o forzar la recarga de la lista).
- **Pasos para reproducir:**
  1. Abrir `Vocabulario > Animales` y marcar 3 pictogramas como favoritos.
  2. Ir a la pestaña `Favoritos` y verificar el orden inicial (`CP-16_03_favoritos_inicial.png`).
  3. Abrir uno de los favoritos que no está primero (o usarlo desde su categoría) varias veces seguidas.
  4. Volver a la pestaña `Favoritos` dentro de la misma sesión: el orden no cambia (`CP-16_04_favoritos_despues_uso.png`).
  5. Cerrar y volver a abrir la app, e ir a `Favoritos`: ahora sí aparece primero el favorito más usado (`CP-16_05_favoritos_tras_reinicio.png`).

### 2. `CP-17` y `CP-18` — Mensajes informativos de bloqueo intercambiados entre ingreso de PIN y recuperación de PIN (y bloqueo compartido)
- **Severidad:** Menor (copys/UX)
- **Descripción:**
  - En la pantalla de bloqueo tras 3 PIN incorrectos (`LoginPinPage`, `CP-17_01_pin_bloqueado_5min.png`), el cuadro informativo dice *"Tu PIN actual sigue funcionando. Si lo recuerdas, puedes entrar con él."* aunque el ingreso con PIN está bloqueado durante 5 minutos.
  - En la pantalla de bloqueo tras 3 respuestas incorrectas de recuperación (`CP-18_04_recuperacion_bloqueada_5min.png`), el cuadro informativo dice *"Por protección de los datos y configuración del menor, el acceso está temporalmente inhabilitado."*, texto que corresponde al bloqueo del acceso por PIN.
  - Adicionalmente, fallar 3 veces la recuperación de PIN (`CP-18`) también bloquea por 5 minutos el ingreso normal por PIN en `Área para padres`, por lo que ambos mensajes quedan invertidos respecto al bloqueo real.
- **Pasos para reproducir:**
  1. En `Área para padres`, ingresar 3 PIN incorrectos (`0000`) y observar el mensaje mostrado debajo del contador de 5 minutos.
  2. Alternativamente, entrar a `¿Olvidaste tu PIN?`, responder incorrectamente 3 veces, observar el texto informativo del bloqueo y luego volver al ingreso de PIN para comprobar que también quedó bloqueado con el contador restante.

### 3. `CP-33` — Subtítulo estático `'2 rutinas'` en categoría `Higiene` al desactivar una rutina
- **Severidad:** Menor (visual/texto)
- **Descripción:** Después de desactivar una de las dos rutinas de `Higiene` y guardar (`1 de 2` activas), la tarjeta de la categoría `Higiene` en la lista de categorías de rutinas sigue mostrando el subtítulo estático `'2 rutinas'`.
- **Pasos para reproducir:**
  1. Ir a `Área de padres > Configuración > Rutinas` (o pantalla de edición de rutinas) y abrir la categoría `Higiene` (`2 de 2` activas).
  2. Desactivar una rutina y tocar `Guardar` (`CP-33_06_guardado_1_de_2.png`).
  3. Abrir `Rutinas` desde `Inicio` y observar que el subtítulo de `Higiene` sigue indicando `'2 rutinas'` pese a tener solo 1 activa.

---

## Pendiente de verificación humana

1. **Casos de cámara (`CP-07` y `CP-08`):** Detección en tiempo real de los 35 objetos (630 pruebas) y botón «Ir a rutina» al apuntar al caño.
2. **Panel técnico de la Cámara (`CP-23`):** Verificar en la compilación QA (`QA=true`) que el panel técnico aparece en el módulo `Cámara` y no aparece en la versión oficial (`QA=false`).
3. **Verificación auditiva de voz TTS (`CP-10`, `CP-11`, `CP-12`, `CP-13`, `CP-14`, `CP-32`):** Confirmar físicamente en el celular que las frases predefinidas, «A mí me gusta…», «Sí»/«No», «Me siento enojada», los pasos de `Ir al doctor` y los pasos del tutorial de Cámara se escuchan correctamente en voz alta sin conexión.
4. **Modo avión estricto sin Wi-Fi (`CP-10` y `CP-22`):** Probar `Pedir algo` y los 7 módulos + `Área de padres` con modo avión activado y el Wi-Fi completamente apagado (en esta sesión el Wi-Fi permaneció encendido para sostener la depuración inalámbrica por ADB).
5. **Recuperación de PIN con tildes usando teclado real (`CP-18`):** Probar ingresar `María` y `Pérez` con tildes desde el teclado táctil de Android (`adb shell input text` solo acepta ASCII).
6. **Contenido interno y limpieza temporal del PDF (`CP-20`):** Abrir el PDF generado para verificar que solo incluya primer nombre/apodo, edad y métricas, y comprobar que el archivo temporal se elimina luego de cerrar la hoja de compartir.
7. **Pantalla fijada y solicitud de PIN del sistema (`CP-21`):** Aunque Ricardo ya ejecutó en vivo el desfijado con su PIN del celular durante esta sesión (observándose la transición de `PINNED` a `NONE`), Android bloquea capturas del diálogo de seguridad del PIN del teléfono.
