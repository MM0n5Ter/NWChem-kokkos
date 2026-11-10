#!/usr/bin/env bash
# Inventory of NWChem's QA suite: number of test directories, how many have
# reference outputs, how many directories use each theory (from `task`
# lines), and how many touch selected features.
#
# Usage: scripts/qa-inventory.sh [NWCHEM_TOP]   (default: deps/nwchem)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOP="${1:-$HERE/../deps/nwchem}"
cd "$TOP/QA/tests"
echo "test directories:        $(ls -d */ | wc -l)"
echo "with reference .out:     $(ls */*.out 2>/dev/null | cut -d/ -f1 | sort -u | wc -l)"
echo "unique tests in doqmtests.mpi: $(grep -o 'runtests.mpi.unix procs \$np .*' ../doqmtests.mpi \
      | sed 's/runtests.mpi.unix procs \$np//' | tr ' ' '\n' | grep . | sort -u | wc -l)"
echo
echo "directories per theory (task <theory> ...):"
for d in */; do
  cat "$d"*.nw 2>/dev/null | grep -iE '^\s*task\s+' | awk '{print tolower($2)}' | sort -u || true
done | sort | uniq -c | sort -rn | head -30
echo
echo "directories per feature (regex on .nw inputs):"
while IFS='|' read -r name re; do
  printf '%7d %s\n' "$(grep -liE "$re" */*.nw 2>/dev/null | cut -d/ -f1 | sort -u | wc -l)" "$name"
done <<'EOF'
optimize/gradient|^\s*task.*(grad|optimize)
freq/hessian|^\s*task.*(freq|hessian)
property|^\s*task.*property
cosmo|cosmo
relativistic (x2c/DK)|x2c|douglas|^\s*relativistic
zora|zora
cd fitting|cd basis|"cd basis"
ecp|^\s*ecp
EOF
