/// Variante de compilación de BrillanTEA.
///
/// * Versión oficial (por defecto): sin opciones de prueba. Los datos solo se borran desde
///   Área de padres > Borrar los datos, con el PIN (US1007, US1206).
/// * Versión QA: agrega «Restablecer onboarding» en el menú lateral y «Restablecer primer uso»
///   en el área de padres, además del panel técnico de la cámara. Se compila con
///   `flutter build apk --release --split-per-abi --dart-define=QA=true`.
library;

const bool kModoQA = bool.fromEnvironment('QA');

/// Panel técnico de la cámara (modelo, CPU/GPU, benchmark, CSV). Sigue a la variante QA salvo que
/// se fije aparte con `--dart-define=MODO_TECNICO=true|false`.
const bool kModoTecnico = bool.fromEnvironment('MODO_TECNICO', defaultValue: kModoQA);
