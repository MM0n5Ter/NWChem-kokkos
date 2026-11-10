#!/usr/bin/env bash
# Where is an API entry point called from? Counts the Fortran files outside
# the owning directory that call each routine, and the top-level modules
# those files are in.
#
# Usage: scripts/api-callers.sh [-o OWNER] ROUTINE...
#   -o OWNER   directory under src/ whose own files are excluded (default NWints)
#   NWCHEM_SRC environment variable overrides deps/nwchem/src
# Example: scripts/api-callers.sh int_init int_2e4c int_2e3c intd_1eh1
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${NWCHEM_SRC:-$HERE/../deps/nwchem/src}"
OWNER=NWints
if [[ "${1:-}" == -o ]]; then OWNER="$2"; shift 2; fi
[[ $# -gt 0 ]] || { sed -n '2,10p' "$0"; exit 1; }
cd "$SRC"
for r in "$@"; do
  hits=$(grep -rliE --include='*.F' --include='*.f' --include='*.F90' --include='*.f90' \
           "\\b$r *\\(" -- * | grep -v "^$OWNER/" || true)
  nf=$(printf '%s' "$hits" | grep -c . || true)
  mods=$(printf '%s\n' "$hits" | cut -d/ -f1 | grep . | sort -u | tr '\n' ' ')
  nm=$(printf '%s' "$mods" | wc -w)
  printf '%-14s files=%-4d modules=%-3d %s\n' "$r" "$nf" "$nm" "$mods"
done
