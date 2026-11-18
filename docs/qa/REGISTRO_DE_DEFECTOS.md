# Registro de defectos

Defectos encontrados al ejecutar los casos de prueba y su corrección. El commit de la corrección es la
evidencia de cierre; su fecha y autor se consultan con `git show <commit>`. Cada defecto se volvió a
verificar con el caso indicado.

| ID | Módulo | Defecto encontrado | Corrección (commit) | Caso que lo verifica | Estado |
|---|---|---|---|---|---|
| DEF-01 | Recursos | Un SVG que no se podía cargar dejaba un espacio vacío. | `9604cd4` fix(assets): show a fallback icon when an SVG cannot be loaded | CP-01, CP-22 | Corregido |
| DEF-02 | Base de datos | La migración al esquema 6 no aplicaba las claves foráneas del catálogo. | `7ab6986` fix(database): enforce catalog foreign keys during schema v6 migration | CP-24 | Corregido |
| DEF-03 | Seguridad | Se podía entrar al área de padres sin un PIN registrado. | `8be862c` fix(security): reject access when no PIN has been registered | CP-17 | Corregido |
| DEF-04 | Privacidad | La versión oficial pedía permiso de internet y permitía transferir datos. | `810d91d` fix(privacy): remove release internet access and disable data transfers | CP-22, CP-23 | Corregido |
| DEF-05 | Favoritos | Con el mismo número de usos, el orden de los favoritos no era estable. | `f628875` fix(favorites): use creation order to break equal usage counts | CP-16 | Corregido |
| DEF-06 | Privacidad | Los PDF temporales de reportes anteriores quedaban en el celular. | `4da2803` fix(privacy): clean stale PDF reports at startup and during data deletion | CP-19, CP-20 | Corregido |
| DEF-07 | Favoritos | Las tarjetas cambiaban de lugar mientras el niño las tocaba. | `d9c0903` fix(favorites): keep cards in place while the child taps them | CP-16 | Corregido |
| DEF-08 | Área de padres | La versión oficial mostraba opciones de restablecimiento de prueba y no ofrecía el borrado protegido. | `f1d6e2a` fix(parents): restrict test resets to QA and expose protected data deletion | CP-19, CP-23 | Corregido |
| DEF-09 | Cámara | Sin reconocimiento no había guía para reintentar y el diagnóstico técnico aparecía en la versión oficial. | `77ca83b` fix(camera): show retry guidance and restrict technical diagnostics to QA | CP-07, CP-23 | Corregido |
| DEF-10 | Rutinas | Faltaban pictogramas empaquetados de algunos pasos. | `da47a8a` fix(routines): restore the missing packaged step pictograms | CP-01, CP-09 | Corregido |
| DEF-11 | Seguridad | La recuperación del PIN no usaba los campos actuales del perfil del adulto. | `826b568` fix(auth): align recovery wrapper with the current profile fields | CP-18 | Corregido |
| DEF-12 | Premios | Algunas metas no se podían lograr con las rutinas de la app. | `7478c49` fix(rewards): keep the goal ranges reachable with the app routines | CP-04, CP-31 | Corregido |
| DEF-13 | Cámara | El botón hacia la rutina no tenía el texto del diseño. | `0d2b19f` fix(camera): label the routine shortcut as in the design | CP-02, CP-08 | Corregido |
| DEF-14 | Documentos legales | Los Términos y la Política no describían la app real (casillas, versión y correos). | `54c3dc1` fix(legal): align the terms and privacy policy with the app | CP-28, CP-29 | Corregido |
| DEF-15 | Área de padres | La sección de aceptación de Privacidad y datos tenía un nombre poco claro. | `eedf314` fix(parents): rename the acceptance section of privacy and data | CP-29 | Corregido |
| DEF-16 | Área de padres | El registro de aceptación no se titulaba «Consentimiento otorgado». | `4f37694` fix(parents): title the consent record "Consentimiento otorgado" | CP-29 | Corregido |
| DEF-17 | Área de padres | Las filas de los documentos legales en Privacidad y datos y en Ayuda y soporte ocultaban el efecto al tocarlas (ListTile dentro de una tarjeta con fondo); Flutter lo marcaba como error en modo de depuración. Lo detectó la ejecución automatizada `2026-11-17_2028`. | `6745bfd` fix(parents): show the tap effect on the legal document rows | CP-39, CP-40 | Corregido |
| DEF-18 | Configuración inicial | La pantalla «Crea un nuevo PIN» del registro calculaba su alto con IntrinsicHeight, pero el PIN en recuadros usa LayoutBuilder, que no admite medidas intrínsecas: en modo de depuración Flutter lanzaba un error de diseño en cada cuadro y en la versión de producción el alto se calculaba sin los recuadros. Lo detectó la prueba de flujo de «Creando el espacio» (ejecuciones automatizadas del 18 de noviembre de 2026). | `9782a3e` fix(registration): lay out the new PIN screen without IntrinsicHeight | CP-43 | Corregido |
| DEF-19 | Favoritos | En Inicio, la pestaña Favoritos queda montada y solo ordenaba por uso al reiniciar la app. Lo detectó la ejecución manual del 18 de noviembre de 2026. | `a7678d5` fix(favorites): reorder favorites when the tab is shown again | CP-16 | Corregido |
| DEF-20 | Seguridad | El aviso del bloqueo por PIN decía que el PIN seguía funcionando y el de la recuperación usaba el texto del PIN; ambos fallos comparten el bloqueo de 5 minutos. Ejecución manual del 18 de noviembre de 2026. | `54ff783` fix(auth): describe the shared PIN lockout on both lock screens | CP-17, CP-18 | Corregido |
| DEF-21 | Rutinas | Las categorías de rutinas tenían subtítulos fijos («2 rutinas») que no cambiaban al desactivar una rutina. Ejecución manual del 18 de noviembre de 2026. | `23b631b` fix(routines): show the active routine count of each category | CP-33 | Corregido |
| DEF-22 | Interfaz | En las hojas inferiores (documentos legales, reporte y Cámara), el botón final quedaba detrás de la barra de navegación de Android. Observado en el celular durante la ejecución manual. | `bb76735` fix(ui): keep bottom sheet buttons above the system navigation bar | CP-29, CP-20 | Corregido |
| DEF-23 | Emociones | Las imágenes de las emociones tenían márgenes y tamaños distintos, y la cuadrícula no estaba centrada. Observado en el celular durante la ejecución manual. | `155416d` fix(emotions): give the emotion pictograms the same size and center | CP-13 | Corregido |

## Cómo registrar un defecto nuevo

1. Agregar una fila con el siguiente ID, el módulo, lo observado y el caso que lo detectó, con estado
   *Abierto*.
2. Corregirlo en una rama `fix/<autor>/<tema>` con un commit `fix(<módulo>): ...`.
3. Volver a ejecutar el caso, anotar el commit y cambiar el estado a *Corregido*.
