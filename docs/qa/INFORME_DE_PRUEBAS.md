# Informe de pruebas

> Plantilla. Completar con los resultados de `bash tool/qa.sh` (archivo
> `docs/qa/evidencias/<fecha>/RESUMEN.md`) y de la ejecución manual.

| Dato | Valor |
|---|---|
| Versión de la app | 0.2.0-alpha.1+14 |
| Commit probado | 6988538 (develop) |
| Fecha de ejecución de las pruebas automatizadas | 17/11/2026, 18:19 (UTC-5) |
| Versión de Flutter | 3.47.5 (stable), Dart 3.13.4 |
| Celular (modelo y Android) | _ |
| Responsables | _ |

## 1. Pruebas automatizadas

| Verificación | Resultado |
|---|---|
| `flutter analyze` | Sin problemas |
| Pruebas aprobadas / fallidas | 77 / 0 |
| Cobertura de líneas total | 5,7 % (469 de 8252 líneas) |

Cobertura por capa (de `docs/qa/evidencias/2026-11-17_1819/cobertura.md`; la raíz `lib/main.dart` tiene 19 líneas y 68,4 %):

| Capa | Líneas | Cubiertas | Cobertura |
|---|---|---|---|
| presentacion | 6884 | 165 | 2,4 % |
| dominio | 807 | 117 | 14,5 % |
| infraestructura | 318 | 20 | 6,3 % |
| datos | 224 | 154 | 68,8 % |

La misma ejecución queda en GitHub Actions (workflow **CI**, artefacto `evidencias-pruebas`).

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
