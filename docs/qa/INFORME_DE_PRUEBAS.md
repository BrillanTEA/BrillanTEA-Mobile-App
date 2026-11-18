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

Ejecución final: `docs/qa/evidencias/2026-11-17_2032/`.

| Verificación | Resultado |
|---|---|
| `flutter analyze` | Sin problemas |
| Archivos de prueba | 15 |
| Pruebas aprobadas / fallidas | 154 / 0 |
| Cobertura de líneas total | 50,1 % (4139 de 8254 líneas) |

Cobertura por capa (la raíz `lib/main.dart` tiene 19 líneas y 68,4 %):

| Capa | Líneas | Cubiertas | Cobertura |
|---|---|---|---|
| datos | 224 | 206 | 92,0 % |
| dominio | 807 | 672 | 83,3 % |
| presentacion | 6886 | 3202 | 46,5 % |
| infraestructura | 318 | 46 | 14,5 % |

La capa de infraestructura queda baja porque contiene la cámara, el modelo TensorFlow Lite y los canales nativos de Android, que solo funcionan en el celular; se verifican con los casos manuales (CP-07, CP-21, CP-23) y con la evaluación del modelo.

Historial de ejecuciones:

| Ejecución | Commit | Aprobadas / fallidas | Cobertura | Observación |
|---|---|---|---|---|
| 2026-11-17_1819 | 6988538 | 77 / 0 | 5,7 % | Primera ejecución con 10 archivos de prueba. |
| 2026-11-17_2028 | b48c9ad | 148 / 6 | 50,1 % | Pruebas nuevas de dominio y de pantallas. Detectaron el defecto DEF-17 (4 fallas) y 2 pruebas que no consideraban que la voz viene desactivada. |
| 2026-11-17_2032 | 56238c6 | 154 / 0 | 50,1 % | Después de corregir DEF-17 y las 2 pruebas. |

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
