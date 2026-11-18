#!/usr/bin/env bash
# Resume un archivo lcov.info (flutter test --coverage) en una tabla Markdown por capa de lib/.
# Además calcula la cobertura sin los archivos de tool/cobertura_excluir.txt (código que solo
# funciona en el celular: cámara, TensorFlow Lite y fijación de pantalla), que es la que se
# compara con la meta del 85 %.
# Uso: bash tool/resumen_cobertura.sh [coverage/lcov.info]
LCOV="${1:-coverage/lcov.info}"
EXCLUIR="$(dirname "$0")/cobertura_excluir.txt"
if [ ! -f "$LCOV" ]; then echo "No existe $LCOV. Corre primero: flutter test --coverage"; exit 1; fi
awk -F: -v excluir="$EXCLUIR" '
BEGIN {
  while ((getline linea < excluir) > 0) {
    sub(/#.*/, "", linea); gsub(/[ \t\r]/, "", linea);
    if (linea != "") { sub(/^lib\//, "", linea); fuera[linea] = 1 }
  }
}
/^SF:/ { f=$2; sub(/^.*lib\//, "", f); n=split(f, p, "/"); capa=(n>1)?p[1]:"(raíz)"; excl=(f in fuera) }
/^LF:/ { lf[capa]+=$2; LF+=$2; if (!excl) LFm+=$2; else { xlf[f]=$2 } }
/^LH:/ { lh[capa]+=$2; LH+=$2; if (!excl) LHm+=$2; else { xlh[f]=$2 } }
END {
  print "| Capa de lib/ | Líneas medidas | Líneas cubiertas | Cobertura |";
  print "|---|---:|---:|---:|";
  for (c in lf) printf "| %s | %d | %d | %.1f %% |\n", c, lf[c], lh[c], (lf[c] ? 100*lh[c]/lf[c] : 0);
  printf "| **Total** | %d | %d | **%.1f %%** |\n", LF, LH, (LF ? 100*LH/LF : 0);
  print "";
  print "Archivos que solo funcionan en el celular (tool/cobertura_excluir.txt):";
  print "";
  print "| Archivo | Líneas medidas | Líneas cubiertas |";
  print "|---|---:|---:|";
  for (x in xlf) printf "| %s | %d | %d |\n", x, xlf[x], xlh[x];
  print "";
  printf "| **Total sin código que requiere el celular** | %d | %d | **%.1f %%** |\n", LFm, LHm, (LFm ? 100*LHm/LFm : 0);
}' "$LCOV"
