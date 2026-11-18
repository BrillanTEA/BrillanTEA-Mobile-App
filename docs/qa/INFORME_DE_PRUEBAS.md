# Informe de pruebas

> Plantilla. Completar con los resultados de `bash tool/qa.sh` (archivo
> `docs/qa/evidencias/<fecha>/RESUMEN.md`) y de la ejecución manual.

| Dato | Valor |
|---|---|
| Versión de la app | 0.2.0-alpha.1+14 |
| Commit probado | 56238c6 (rama test/ricardo/domain-widget-tests, integrada en develop) |
| Fecha de ejecución de las pruebas automatizadas | 17/11/2026, 20:32 (UTC-5) |
| Versión de Flutter | 3.47.5 (stable), Dart 3.13.4 |
| Celular (modelo y Android) | _ |
| Responsables | _ |

## 1. Pruebas automatizadas

Ejecución final: `docs/qa/evidencias/2026-11-18_1555/` (commit `01c6fa0`, con las correcciones de la ejecución manual).

| Verificación | Resultado |
|---|---|
| `flutter analyze` | Sin problemas |
| Archivos de prueba | 40 |
| Pruebas aprobadas / fallidas | 257 / 0 |
| Cobertura sin el código que requiere el celular (meta ≥ 85 %) | 94,0 % (6867 de 7304 líneas) |
| Cobertura de líneas global | 82,9 % (6882 de 8301 líneas) |

Cobertura por capa (la raíz `lib/main.dart` tiene 19 líneas y 68,4 %):

| Capa | Líneas | Cubiertas | Cobertura |
|---|---|---|---|
| datos | 224 | 206 | 92,0 % |
| dominio | 807 | 756 | 93,7 % |
| presentacion | 6919 | 5696 | 82,3 % |
| infraestructura | 332 | 211 | 63,6 % |

La diferencia entre las dos coberturas son tres archivos que solo funcionan en el celular
(`tool/cobertura_excluir.txt`): la pantalla de la Cámara (863 líneas), el motor de TensorFlow Lite
(115) y la fijación de pantalla (19). Se verifican con los casos manuales (CP-07, CP-21, CP-23) y con
la evaluación del modelo. Para poder probar el resto en el computador, el pre y posprocesamiento del
modelo se separó en `procesador_yolo.dart` y la ubicación de las tarjetas de realidad aumentada en
`realidad_aumentada.dart`.

Historial de ejecuciones:

| Ejecución | Commit | Aprobadas / fallidas | Cobertura | Observación |
|---|---|---|---|---|
| 2026-11-17_1819 | 6988538 | 77 / 0 | 5,7 % | Primera ejecución con 10 archivos de prueba. |
| 2026-11-17_2028 | b48c9ad | 148 / 6 | 50,1 % | Pruebas nuevas de dominio y de pantallas. Detectaron el defecto DEF-17 (4 fallas) y 2 pruebas que no consideraban que la voz viene desactivada. |
| 2026-11-17_2032 | 56238c6 | 154 / 0 | 50,1 % | Después de corregir DEF-17 y las 2 pruebas. |
| 2026-11-18_0106 | 57ea686 | 183 / 14 | 54,2 % (62,8 % sin celular) | Pruebas de flujos y exploratorias nuevas. Interrumpida: varias pruebas se quedaban esperando la base de datos. |
| 2026-11-18_0234 | 57ea686 | 173 / 24 | 51,4 % (59,5 %) | Misma versión; las esperas se encadenaban dentro de cada archivo. |
| 2026-11-18_0739 | be234a4 | 221 / 7 | 75,0 % (86,8 %) | Pruebas en archivos pequeños con límite de tiempo. |
| 2026-11-18_0811 | 023d213 | 226 / 1 | 76,4 % (88,4 %) | Limpieza de cada prueba dentro del reloj simulado. |
| 2026-11-18_0822 | f6e299a | 245 / 6 | 82,1 % (93,1 %) | Procesador YOLO separado y probado; flujos nuevos. |
| 2026-11-18_0832 | 757e982 | 251 / 2 | 82,5 % (93,5 %) | Correcciones de pruebas. |
| 2026-11-18_0920 | f52cdf4 | 251 / 3 | 82,5 % (93,6 %) | La prueba de «Creando el espacio» reveló DEF-18. |
| 2026-11-18_0934 | 986dd34 | 245 / 6 | 81,4 % (92,4 %) | Antes de corregir DEF-18. |
| 2026-11-18_0956 | a99af4a | 253 / 0 | 82,8 % (94,0 %) | Después de corregir DEF-18 y separar las pruebas del registro en archivos propios. |

La misma ejecución se repite en GitHub Actions (workflow **CI**, artefacto `evidencias-pruebas`) al subir los cambios.

## 2. Pruebas manuales

Ejecución del 18 de noviembre de 2026 en un Samsung Galaxy A25 (SM-A256E, Android 16) con la versión
oficial 0.2.0-alpha.1+14 (commit `6b7b536`). Los pasos se ejecutaron por adb con un agente de IA
(Antigravity), que tomó las capturas; Ricardo Barrutia ejecutó los pasos que requieren el celular en la
mano (PIN del celular). El detalle de cada caso, con sus capturas, está en
[RESULTADOS_MANUALES.md](evidencias/2026-11-18_manuales/RESULTADOS_MANUALES.md). «Parcial» indica que se verificó lo visible en
pantalla y falta una verificación humana (voz, red apagada, teclado o cámara).

| Caso | Resultado | Observación o defecto | Captura |
|---|---|---|---|
| CP-07 | No ejecutado | Pendiente: evaluación con los 35 objetos reales (630 pruebas). | — |
| CP-08 | No ejecutado | Pendiente: apuntar al caño y «Ir a rutina». | — |
| CP-09 | Aprobado | — | `CP-09_*` |
| CP-10 | Parcial | La petición se registró con modo avión; falta escuchar la voz y repetir con el Wi-Fi apagado (se mantuvo para adb). | `CP-10_*` |
| CP-11 | Parcial | La frase se arma bien; falta escuchar la voz. | `CP-11_*` |
| CP-12 | Parcial | Falta escuchar la voz. | `CP-12_*` |
| CP-13 | Parcial | Se registra una sola vez y en femenino; falta escuchar la voz. Las imágenes de emociones tenían tamaños distintos y no estaban centradas (DEF-23 y DEF-24, corregidos). | `CP-13_*` |
| CP-14 | Parcial | Falta escuchar la voz. | `CP-14_*` |
| CP-15 | Aprobado | — | `CP-15_*` |
| CP-16 | Fallido | Favoritos no se reordenaba al volver a la pestaña (DEF-19, corregido; repetir). | `CP-16_*` |
| CP-17 | Aprobado | El aviso del bloqueo decía que el PIN seguía funcionando (DEF-20, corregido). | `CP-17_*` |
| CP-18 | Parcial | Respuestas sin tildes por limitación de adb; falta probar con tildes desde el teclado. Aviso de bloqueo corregido (DEF-20). | `CP-18_*` |
| CP-19 | Aprobado | — | `CP-19_*` |
| CP-20 | Parcial | Se muestra el contenido y la hoja de compartir; falta abrir el PDF y revisar su contenido. | `CP-20_*` |
| CP-21 | Parcial | No se pudo salir de la app fijada; Ricardo la desfijó con el PIN del celular. Android no permite capturar ese diálogo. | `CP-21_*` |
| CP-22 | Parcial | Todo funcionó con modo avión; falta repetir con el Wi-Fi apagado y en la Cámara. | `CP-22_*` |
| CP-23 | Parcial | APK de 75 a 83 MiB; la versión QA muestra «Restablecer onboarding (QA)» y la oficial no; falta revisar el panel técnico de la Cámara. | `CP-23_*` |
| CP-29 | Aprobado | En la Política de privacidad, «Entendido» quedaba detrás de la barra de navegación (DEF-22, corregido). | `CP-29_*` |
| CP-30 | Aprobado | — | `CP-30_*` |
| CP-31 | Aprobado | — | `CP-31_*` |
| CP-32 | Parcial | Falta escuchar la lectura en voz. | `CP-32_*` |
| CP-33 | Aprobado | La categoría seguía diciendo «2 rutinas» (DEF-21, corregido). | `CP-33_*` |
| CP-34 | Aprobado | — | `CP-34_*` |

En las capturas se cubrieron los datos personales del celular que aparecían en la hoja de compartir y en
la app de correo.

## 3. Defectos

Defectos abiertos al cierre: _ (ver [REGISTRO_DE_DEFECTOS.md](REGISTRO_DE_DEFECTOS.md)).

## 4. Conclusión

_¿Se cumplen los criterios de salida del [plan](PLAN_DE_PRUEBAS.md#4-criterios)?_
