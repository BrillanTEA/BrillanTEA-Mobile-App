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

Ejecución final: `docs/qa/evidencias/2026-11-18_0956/` (commit `a99af4a`).

| Verificación | Resultado |
|---|---|
| `flutter analyze` | Sin problemas |
| Archivos de prueba | 40 |
| Pruebas aprobadas / fallidas | 253 / 0 |
| Cobertura sin el código que requiere el celular (meta ≥ 85 %) | 94,0 % (6842 de 7282 líneas) |
| Cobertura de líneas global | 82,8 % (6857 de 8278 líneas) |

Cobertura por capa (la raíz `lib/main.dart` tiene 19 líneas y 68,4 %):

| Capa | Líneas | Cubiertas | Cobertura |
|---|---|---|---|
| datos | 224 | 206 | 92,0 % |
| dominio | 807 | 756 | 93,7 % |
| presentacion | 6896 | 5671 | 82,2 % |
| infraestructura | 332 | 211 | 63,6 % |

La diferencia entre las dos coberturas son tres archivos que solo funcionan en el celular
(`tool/cobertura_excluir.txt`): la pantalla de la Cámara (862 líneas), el motor de TensorFlow Lite
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

| Caso | Resultado (Aprobado / Fallido / No ejecutado) | Observación o defecto | Captura |
|---|---|---|---|
| CP-07 | | | |
| CP-08 | | | |
| CP-09 | | | |
| CP-10 | | | |
| CP-11 | | | |
| CP-12 | | | |
| CP-13 | | | |
| CP-14 | | | |
| CP-15 | | | |
| CP-16 | | | |
| CP-17 | | | |
| CP-18 | | | |
| CP-19 | | | |
| CP-20 | | | |
| CP-21 | | | |
| CP-22 | | | |
| CP-23 | | | |
| CP-29 | | | |
| CP-30 | | | |
| CP-31 | | | |
| CP-32 | | | |
| CP-33 | | | |
| CP-34 | | | |

## 3. Defectos

Defectos abiertos al cierre: _ (ver [REGISTRO_DE_DEFECTOS.md](REGISTRO_DE_DEFECTOS.md)).

## 4. Conclusión

_¿Se cumplen los criterios de salida del [plan](PLAN_DE_PRUEBAS.md#4-criterios)?_
