# Testing

## What NWChem already has
Counts from `scripts/qa-inventory.sh`:
- **`QA/tests`:** 692 test directories. **681** have reference `.out` files and are compared within tolerances by `QA/nwparse.pl`, `nwparse.py` and `nwdiff.py`.
  - Directories per theory (`task <theory>`): dft 361, tddft 85, scf 78, tce 61, pspw 59, mp2 17, sodft 15, dplot 13, qmmm 9, rimp2 8, direct_mp2 8, md 7, ccsd(t) 6, mcscf 4, xtb 3, python 3, esp 3, lucia 2, selci 1.
  - Directories per feature: optimize/gradient 210, freq/hessian 68, property 58, cosmo 40, relativistic (x2c/DK) 37, cd fitting 31, zora 30, ecp 23.
- **Runners:** `QA/doqmtests.mpi` (381 unique tests, with a `fast` mode). Separate scripts cover MD, QM/MM, TCE and libxc. The runners are bash calling `runtests.mpi.unix`.
- **`small_intchk`:** written to check "all valid integral and integral derivative paths" (McMurchie–Davidson vs Texas; sp, spherical and general contractions). A ready-made oracle for NWints.
- **GitHub Actions** (`.github/workflows/github_actions.yml`) builds **module subsets**: `"nwdft driver solvation"`, `"tce"`, `"tinyqmpw python"`, … So each lane can build only what it touches.
- **Smaller harnesses:**
  - `src/python/tests` (`.nw` inputs);
  - `src/nwxc/nwad/unit_tests` (114 `.F` files);
  - `src/fft/test`;
  - the Fortran drivers in `src/develop` (`rak*.F`, `raktest.F`, `jantest.F`, …), which call `int_init`, `int_2e4c`, ….
- **Areas with thin coverage** (add tests *before* porting): mcscf (4 dirs), selci (1), lucia (2), xtb (3), dirdyvtst/drdy (3), and anything the coverage map shows no QA test reaches.

## Our test levels
| Level | What | Built by | Runs |
|---|---|---|---|
| L0 | Unit differential test. The frozen Fortran is the oracle, inputs are randomized (lesson from Gupta et al.), and the Fortran and C++ outputs are compared. | Lane C (harness), filled per unit | Every commit |
| L1 | The QA subset that **covers the unit**, selected from a gcov coverage map (QA test → file → unit) | Lane C | Every commit |
| L2 | Full QA suite (681 cases with references) at NWChem's tolerances | CI | Nightly and pre-merge |
| L3 | Downstream workflows from [downstream.md](downstream.md) (ChemShell QM/MM, ASE file and socket, QCEngine, Python scripts), zero consumer edits, comparing energies, forces and parsed fields | Lane D | Pre-merge for units on the external path; otherwise nightly |

- Before porting anything, run L2 and L3 on the **unmodified** baseline and record known failures and timings. A gate fails only on regressions, not on problems that were already there.
- Validation ladder (from FESOM2):
  - bit-for-bit on the serial CPU backend where achievable;
  - NWChem's tolerances otherwise;
  - identical output across MPI rank counts.

## Do we port the tests first? No
- **QA (L2) does not depend on the source language.** It is `.nw` inputs, reference `.out` files, bash runners and the Perl/Python parser, and it runs the `nwchem` binary. Nothing needs porting. That independence is what makes it a valid judge of the port.
- **The oracle must not be translated by the same agent before the code it checks.** A test translated together with the code can share its mistakes, and then both agree on a wrong answer. Tests stay at least one step behind the code they check.
- **Fortran test drivers are API consumers.** The `src/develop` drivers and `src/nwxc/nwad/unit_tests` stay in Fortran while their unit is ported, and call it through the shim. That exercises the API gate for free. They are ported or replaced by C++ tests **after** their unit, before the shim is deleted.
- **Before porting a unit, we *add* tests:**
  1. L0 characterization tests: record what the Fortran outputs on randomized inputs.
  2. New QA cases where coverage is thin.
  3. Output-format checks for the fields downstream parsers read.
- **`deps/nwchem` is the frozen oracle.** After a unit's Fortran is deleted from the port, L0 still compares against the baseline build.
