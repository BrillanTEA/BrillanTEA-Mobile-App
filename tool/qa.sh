#!/usr/bin/env bash
# Ejecuta el análisis estático y las pruebas automatizadas y guarda la evidencia para el informe
# de pruebas (Memoria, 4.4.3). Crea docs/qa/evidencias/<fecha>/ con:
#   entorno.txt        versión de Flutter, commit y versión de la app
#   flutter_analyze.txt salida de flutter analyze
#   flutter_test.txt   salida de flutter test (reporter expanded)
#   flutter_test.json  resultados de cada prueba en formato JSON
#   lcov.info y cobertura.md  cobertura de líneas por capa
#   RESUMEN.md         resultado general para copiar en el informe
# Uso (en la carpeta del proyecto): bash tool/qa.sh
set -u
cd "$(dirname "$0")/.."
FECHA=$(date +%Y-%m-%d_%H%M)
DIR="docs/qa/evidencias/$FECHA"
mkdir -p "$DIR"

{
  flutter --version
  echo
  git log -1 --format='Commit: %H%nFecha del commit: %ci%nMensaje: %s'
  echo "Rama: $(git rev-parse --abbrev-ref HEAD)"
  grep '^version:' pubspec.yaml
  echo "Ejecutado: $(date '+%Y-%m-%d %H:%M:%S %z')"
} > "$DIR/entorno.txt" 2>&1

flutter pub get > /dev/null 2>&1

flutter analyze > "$DIR/flutter_analyze.txt" 2>&1
ANALYZE=$?

flutter test --coverage --reporter expanded --file-reporter "json:$DIR/flutter_test.json" > "$DIR/flutter_test.txt" 2>&1
TEST=$?

COBERTURA="sin datos"
if [ -f coverage/lcov.info ]; then
  cp coverage/lcov.info "$DIR/lcov.info"
  bash tool/resumen_cobertura.sh coverage/lcov.info > "$DIR/cobertura.md"
  COBERTURA=$(grep '^| \*\*Total' "$DIR/cobertura.md" | awk -F'|' '{gsub(/[ *]/,"",$5); print $5}')
fi

ULTIMA=$(grep -oE '\+[0-9]+( ~[0-9]+)?( -[0-9]+)?: (All tests passed!|Some tests failed\.)' "$DIR/flutter_test.txt" | tail -1)
APROBADAS=$(echo "$ULTIMA" | grep -oE '^\+[0-9]+' | tr -d '+')
FALLIDAS=$(echo "$ULTIMA" | grep -oE ' -[0-9]+' | tr -d ' -')

{
  echo "# Resumen de la ejecución de pruebas ($FECHA)"
  echo
  echo "| Verificación | Resultado |"
  echo "|---|---|"
  echo "| flutter analyze | $([ $ANALYZE -eq 0 ] && echo 'Sin problemas' || echo "Con problemas (código $ANALYZE), ver flutter_analyze.txt") |"
  echo "| flutter test | $([ $TEST -eq 0 ] && echo 'Todas las pruebas pasaron' || echo 'Hay pruebas fallidas, ver flutter_test.txt') |"
  echo "| Pruebas aprobadas | ${APROBADAS:-?} |"
  echo "| Pruebas fallidas | ${FALLIDAS:-0} |"
  echo "| Cobertura de líneas (archivos cargados por las pruebas) | $COBERTURA |"
  echo
  echo "Entorno: ver entorno.txt. Cobertura por capa: ver cobertura.md."
} > "$DIR/RESUMEN.md"

cat "$DIR/RESUMEN.md"
echo
echo "Evidencias guardadas en $DIR"
[ $ANALYZE -eq 0 ] && [ $TEST -eq 0 ]
