# BrillanTEA

Aplicación Android para niños con TEA de Nivel 2. Funciona sin internet: la detección de objetos,
la voz y los datos están en el celular.

## Arquitectura (Clean Architecture)

Cuatro capas con dependencias en un solo sentido: presentación → dominio → infraestructura y datos.

```
lib/
├── main.dart
├── presentacion/            Pantallas (Flutter), una carpeta por módulo
│   ├── comun/               Piezas compartidas (PIN, SVG, formateadores)
│   ├── registro/            Bienvenida, Términos y privacidad, perfiles y PIN del primer uso
│   ├── inicio/              Inicio con los 7 módulos
│   ├── camara/              Módulo 1: cámara y realidad aumentada
│   ├── rutinas/             Módulo 2: rutinas
│   ├── comunicacion/        Módulo 3: Pedir algo, Armar mi frase, Responder
│   ├── vocabulario/         Módulo 4: vocabulario, emociones y favoritos
│   ├── situaciones/         Módulo 5: situaciones
│   ├── calma/               Calma
│   ├── premios/             Premios
│   └── area_padres/         Módulo 6: área de padres, PIN, seguimiento, privacidad y datos, tutoriales
├── dominio/                 Lógica de la app
│   ├── catalogo_service     Motor de Asociación (objeto → pictograma → frase)
│   ├── rutinas_app          Motor de Rutinas: rutinas, pasos y «Ir a rutina»
│   ├── rutinas_service      Progreso diario y rutinas activas
│   ├── auth_service         Gestor de Perfiles y de Seguridad (PIN con PBKDF2)
│   ├── accesibilidad_service, favoritos_service, premios_service, tutoriales_service
│   ├── registro_uso_service Registro de Uso (seguimiento)
│   └── reporte_service      Generador de Reportes (PDF)
├── infraestructura/         Adaptadores hacia el celular
│   ├── detector_worker      Motor de Inferencia Edge AI (TensorFlow Lite)
│   ├── servicio_voz         Servicio de Voz (TextToSpeech de Android)
│   ├── bloqueo_service      Gestor de Bloqueo (fijación de pantalla)
│   └── stats                Medición de latencia (panel técnico)
└── datos/
    └── base_datos           Repositorio Local: único acceso a SQLite (catalogo.db)
```

## Comandos (en esta carpeta)

- Pruebas: `flutter test` (con cobertura: `flutter test --coverage`)
- Análisis, pruebas y evidencias en un paso: `bash tool/qa.sh`
- APK versión oficial: `flutter build apk --release --split-per-abi --dart-define=QA=false` (sin opciones de prueba; los datos solo se borran desde Área de padres > Privacidad y datos > Borrar los datos, con PIN)
- APK versión QA: `flutter build apk --release --split-per-abi --dart-define=QA=true` (agrega Restablecer onboarding, Restablecer primer uso y el panel técnico de la cámara)
- Con `flutter run` también es la oficial por defecto; para QA: `flutter run --dart-define=QA=true`

## Pruebas y calidad

- `test/` tiene 15 archivos de pruebas unitarias, de integración con SQLite y de widgets: PIN,
  recuperación y consentimiento, premios y rutinas, favoritos y registro de uso, accesibilidad,
  catálogo y migraciones de la base, contrato del modelo, comunicación, vocabulario y emociones,
  tutoriales, documentos legales y 22 pantallas con sus flujos principales. `test/soporte/` crea la
  base SQLite temporal y simula la voz de Android.
- `bash tool/qa.sh` ejecuta `flutter analyze` y `flutter test --coverage` y guarda la evidencia en
  `docs/qa/evidencias/<fecha>/` (resumen, salida de las pruebas en texto y JSON, cobertura por capa y entorno).
- CI: `.github/workflows/ci.yml` repite el análisis y las pruebas en cada push a `develop` o `main` y en
  cada pull request; el resumen de cobertura y el artefacto `evidencias-pruebas` quedan en *Actions*.
- `docs/qa/` reúne el [plan de pruebas](docs/qa/PLAN_DE_PRUEBAS.md), los
  [casos de prueba](docs/qa/CASOS_DE_PRUEBA.md), el [registro de defectos](docs/qa/REGISTRO_DE_DEFECTOS.md),
  el [informe de pruebas](docs/qa/INFORME_DE_PRUEBAS.md) y el [certificado QA](docs/qa/CERTIFICADO_QA.md).

## Detección

El paquete integra el candidato020 de YOLO26 para las 35 clases estables.
Su contrato y SHA-256 están en `assets/models/contrato_yolo26_35.json` y `lib/infraestructura/perfil_yolo26.dart`.
La tarea US301 de entrenamiento y evaluación sigue en curso; integrar este candidato no acredita una validación final.
