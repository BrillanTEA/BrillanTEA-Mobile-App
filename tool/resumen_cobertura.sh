#!/usr/bin/env bash
# Resume un archivo lcov.info (flutter test --coverage) en una tabla Markdown por capa de lib/.
# Uso: bash tool/resumen_cobertura.sh [coverage/lcov.info]
LCOV="${1:-coverage/lcov.info}"
if [ ! -f "$LCOV" ]; then echo "No existe $LCOV. Corre primero: flutter test --coverage"; exit 1; fi
awk -F: '
/^SF:/ { f=$2; sub(/^.*lib\//, "", f); n=split(f, p, "/"); capa=(n>1)?p[1]:"(raíz)" }
/^LF:/ { lf[capa]+=$2; LF+=$2 }
/^LH:/ { lh[capa]+=$2; LH+=$2 }
END {
  print "| Capa de lib/ | Líneas medidas | Líneas cubiertas | Cobertura |";
  print "|---|---:|---:|---:|";
  for (c in lf) printf "| %s | %d | %d | %.1f %% |\n", c, lf[c], lh[c], (lf[c] ? 100*lh[c]/lf[c] : 0);
  printf "| **Total** | %d | %d | **%.1f %%** |\n", LF, LH, (LF ? 100*LH/LF : 0);
}' "$LCOV"
