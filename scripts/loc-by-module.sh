#!/usr/bin/env bash
# Lines of Fortran (.F .f .f90 .F90 .fh) and C/C++/CUDA (.c .cpp .cu .h)
# per top-level directory of NWChem's src/, sorted by Fortran lines.
#
# Usage: scripts/loc-by-module.sh [NWCHEM_SRC]   (default: deps/nwchem/src)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${1:-$HERE/../deps/nwchem/src}"
cd "$SRC"
count() { find "$1" -type f \( "${@:2}" \) -print0 | xargs -0 cat 2>/dev/null | wc -l; }
printf '%10s %10s  %s\n' fortran c_cxx module
for d in */; do
  d="${d%/}"
  f=$(count "$d" -name '*.F' -o -name '*.f' -o -name '*.f90' -o -name '*.F90' -o -name '*.fh')
  c=$(count "$d" -name '*.c' -o -name '*.cpp' -o -name '*.cu' -o -name '*.h')
  printf '%10d %10d  %s\n' "$f" "$c" "$d"
done | sort -n
