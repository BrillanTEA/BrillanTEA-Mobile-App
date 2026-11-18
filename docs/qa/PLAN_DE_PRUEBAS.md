# Plan de pruebas de BrillanTEA

Versión del plan: 1.1 · Versión de la app: 0.2.0-alpha.2+15

Este plan define cómo se verifica que la aplicación cumple los requisitos funcionales (RF) y no
funcionales (RNF) de la Memoria (Tabla 13 y siguientes). Los casos están en
[CASOS_DE_PRUEBA.md](CASOS_DE_PRUEBA.md), los defectos en
[REGISTRO_DE_DEFECTOS.md](REGISTRO_DE_DEFECTOS.md) y los resultados en
[INFORME_DE_PRUEBAS.md](INFORME_DE_PRUEBAS.md).

## 1. Alcance

| Incluido | Excluido |
|---|---|
| Los siete módulos, el registro del primer uso, el área de padres y la base de datos local. | El entrenamiento y la evaluación del modelo YOLO26 (US301), que tienen su propio protocolo y métricas. |
| La versión oficial y la versión QA del APK. | Pruebas con niños; la validación con usuarios se reporta aparte. |

## 2. Niveles y tipos de prueba

| Nivel | Herramienta | Qué cubre | Cuándo se ejecuta |
|---|---|---|---|
| Análisis estático | `flutter analyze` (reglas de `flutter_lints`) | Errores, advertencias e infos del código Dart. | En cada push y pull request (CI) y con `tool/qa.sh`. |
| Unitarias, de integración con SQLite y de widgets | `flutter test` (`test/`, 40 archivos) | Servicios de dominio sobre una base SQLite real en una carpeta temporal (PIN, recuperación, consentimiento, premios, rutinas, favoritos, registro de uso, accesibilidad, tutoriales, catálogo y migraciones), contrato del modelo, pre y posprocesamiento de YOLO, ubicación de las tarjetas de realidad aumentada, comunicación, vocabulario, emociones, documentos legales, flujos completos de cada módulo y del área de padres, y pruebas exploratorias que tocan cada control de 36 pantallas. | En cada push y pull request (CI) y con `tool/qa.sh`. |
| Cobertura | `flutter test --coverage` + `tool/resumen_cobertura.sh` | Porcentaje de líneas cubiertas por capa (`presentacion`, `dominio`, `infraestructura`, `datos`). Meta: al menos 85 % sin los archivos de `tool/cobertura_excluir.txt` (cámara, motor de TensorFlow Lite y fijación de pantalla, que solo funcionan en el celular y se verifican con los casos manuales); la cobertura global se informa aparte. `tool/qa.sh` falla si no se cumple. | Igual que las pruebas. |
| Funcionales manuales | Casos CP marcados como *Manual* | Flujos completos en un celular Android: cámara, voz, PIN, bloqueo, reportes y modo sin conexión. | Antes de cada versión que se entrega para pruebas. |
| Aceptación QA externa | [CERTIFICADO_QA.md](CERTIFICADO_QA.md) | Revisión independiente de los casos manuales sobre el APK entregado. | Al cerrar la versión. |

## 3. Entorno

- Flutter estable (la versión exacta queda en `entorno.txt` de cada ejecución).
- CI: GitHub Actions, `.github/workflows/ci.yml`, en `ubuntu-latest`.
- Pruebas manuales: celular Android físico con la versión oficial (`--dart-define=QA=false`) y la
  versión QA (`--dart-define=QA=true`). El modelo y la versión de Android del equipo se anotan en el
  informe.
- Usuarios de prueba: perfiles ficticios; no se usan datos ni fotos de niños reales.

## 4. Criterios

**Entrada:** la rama `develop` compila y el APK se instala en un celular limpio.

**Salida (versión aprobada):**

1. `flutter analyze` sin problemas.
2. El 100 % de las pruebas automatizadas aprobadas y al menos 85 % de cobertura de líneas sin el código
   que requiere el celular.
3. El 100 % de los casos manuales críticos aprobados (CP-07 a CP-10, CP-17 a CP-23, CP-29 y CP-30) y
   al menos el 90 % del total de casos manuales.
4. Ningún defecto abierto que impida usar un módulo o que exponga datos.
5. El certificado QA de un revisor externo no es criterio de salida de esta versión: se obtiene en el
   siguiente ciclo del proyecto, junto con la validación con usuarios.

**Suspensión:** si falla la instalación, la cámara o el ingreso con PIN, se detiene la ejecución
manual hasta corregirlo.

## 5. Gestión de defectos

Cada falla se registra en [REGISTRO_DE_DEFECTOS.md](REGISTRO_DE_DEFECTOS.md) con el caso que la
detectó, se corrige en una rama `fix/...` con un commit `fix(<módulo>): ...` y se vuelve a ejecutar el
caso. El commit de la corrección es la evidencia de cierre.

## 6. Evidencias

| Evidencia | Dónde queda |
|---|---|
| Ejecución local de análisis, pruebas y cobertura | `bash tool/qa.sh` → `docs/qa/evidencias/<fecha>/` (`RESUMEN.md`, `flutter_test.txt`, `flutter_test.json`, `cobertura.md`, `lcov.info`, `flutter_analyze.txt`, `entorno.txt`). |
| Ejecución en CI | Pestaña *Actions* del repositorio: resumen de cobertura del job y artefacto `evidencias-pruebas`. |
| Pruebas manuales | Tabla de resultados del [INFORME_DE_PRUEBAS.md](INFORME_DE_PRUEBAS.md) con capturas en `docs/qa/evidencias/<fecha>/capturas/`. |
| Aceptación | [CERTIFICADO_QA.md](CERTIFICADO_QA.md) firmado. |

## 7. Trazabilidad requisito → caso

| Requisito | Casos |
|---|---|
| RF-01 Captura de imágenes | CP-07 |
| RF-02 Detección de objetos | CP-01, CP-03, CP-07, CP-38 |
| RF-03 Asociación objeto–pictograma | CP-02, CP-08, CP-36 |
| RF-04 Rutinas guiadas | CP-09, CP-36 |
| RF-05 Pedir algo | CP-10, CP-25, CP-40 |
| RF-06 Configuración inicial y PIN | CP-05, CP-18, CP-24, CP-28, CP-29, CP-35, CP-39 |
| RF-07 Bloqueo de la aplicación | CP-21 |
| RF-08 Área de padres | CP-17, CP-19, CP-30, CP-33, CP-35, CP-39, CP-40 |
| RF-09 Vocabulario | CP-26, CP-39 |
| RF-10 Favoritos | CP-16, CP-37, CP-39 |
| RF-11 Emociones | CP-13, CP-26, CP-39, CP-40 |
| RF-12 Armar frase | CP-11, CP-25, CP-39 |
| RF-13 Responder | CP-12, CP-40 |
| RF-14 Situaciones | CP-14, CP-39 |
| RF-15 Seguimiento y reporte | CP-20, CP-37, CP-39 |
| RF-16 Accesibilidad | CP-06, CP-38, CP-39 |
| RF-17 Ayuda y soporte | CP-28, CP-34, CP-39, CP-40 |
| RF-18 Calma | CP-15, CP-38, CP-39 |
| RF-19 Premios | CP-04, CP-09, CP-31, CP-36, CP-39, CP-40 |
| RF-20 Tutoriales | CP-27, CP-32, CP-38, CP-39, CP-40 |
| RNF-01 Latencia de inferencia | CP-38 (cálculo de estadísticas); la medición en el celular se reporta en el capítulo 5 |
| RNF-02 Funcionamiento sin conexión | CP-22 |
| RNF-04 Privacidad del reporte | CP-20 |
| RNF-05 Tamaño y versiones del APK | CP-23 |
