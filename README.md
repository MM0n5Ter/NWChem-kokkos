# NWChem-kokkos

An agentic, **API-preserving**, repository-level migration of [NWChem](https://github.com/nwchemgit/nwchem) from Fortran to C++/Kokkos.
- The agent replaces NWChem one API unit at a time, in dependency order, behind frozen interfaces.
- After every step the repository still builds, and its callers and downstream codes (ChemShell, ASE, QCEngine, the Python module) keep working with zero source edits.
- Every step must pass three gates: **API**, **Regression** and **Performance**.
- The end state is a Fortran-free NWChem that runs on CPUs and GPUs from one Kokkos source.

| Path | Contents |
|---|---|
| `notes/` | Working notes: decisions, landscape, NWChem structure, downstream consumers, testing, roadmap ([index](notes/README.md)) |
| `deps/nwchem/` | Submodule: upstream NWChem, pinned to master `be3ca06d` (2026-10-29). It is the frozen baseline and the oracle for every comparison. **Never edit it.** |
| `scripts/` | Analysis scripts that produce the numbers in `notes/`. Each one defaults to `deps/nwchem`. |

Planned top-level directories, added when their work starts (see [roadmap](notes/roadmap.md)):
- `tools/`: interface/contract extractor, shim generator, gated test harness.
- `tests/`: L0 differential tests and the downstream (L3) workflows.
- The NWChem fork where the port happens. Where it lives is an open decision (see [decisions](notes/decisions.md)).

## Getting started

```bash
git clone --recurse-submodules https://github.com/MM0n5Ter/NWChem-kokkos.git
# or, in an existing clone:
git submodule update --init --depth 1 deps/nwchem
```

The submodule is shallow (`shallow = true` in `.gitmodules`), which is enough for reading the pinned tree.

## Scripts

| Script | What it reports |
|---|---|
| `scripts/loc-by-module.sh` | Lines of Fortran and C/C++ per top-level directory of `src/` |
| `scripts/api-callers.sh int_init int_2e4c …` | For each routine: files and modules outside its owner (default `NWints`) that call it |
| `scripts/xdeps.py [--top N] [--json out]` | Cross-module call graph: fan-in, fan-out and exported routines per module (regex-based, approximate, ~30 s) |
| `scripts/qa-inventory.sh` | QA suite: test directories, reference outputs, directories per theory and per feature |

## Status

Phase 0 (foundations) has not started. See [roadmap](notes/roadmap.md).
