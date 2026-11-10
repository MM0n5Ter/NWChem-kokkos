# Decisions and story (drafted 2026-11-10)

## The story
- Much of computational science still runs on Fortran written for CPUs, while today's machines get most of their FLOPs from GPUs. C++/Kokkos gives one performance-portable source, but porting by hand costs person-years.
- LLM agents can already port **kernels** (Gupta et al.). Agent-assisted **application** ports (NICAM, FESOM2, ORB5X) are human-directed standalone rewrites. **Repo-level** automation still fails at scale (ParEval-Repo, RustRepoTrans). See [landscape.md](landscape.md).
- NWChem is a **library** as well as a program:
  - its own modules call its integral API (NWints);
  - ChemShell links it in;
  - ASE, QCEngine and i-PI drive it through input decks, printed output and sockets.

  A standalone rewrite would break all of these users. We migrate it **in place**, keep every interface, and gate every step.

## Decisions
1. **Pinned upstream: NWChem master `be3ca06d` (2026-10-29), not the latest release.**
   - The latest release, v7.3.1 (`e2869a2c`, 2025-11-06), is a year older than master.
   - All measurements in these notes are on `be3ca06d`.
   - Moving the pin is a deliberate commit that re-runs `scripts/` and updates the numbers.
2. **End state: the whole repository is Fortran-free.** It is reached incrementally. The repository builds and passes its tests after every step.
3. **The unit of work is an API contract, not a directory.**
   - NWChem's own docs define five tiers (`doc/prog/nwarch.tex`). Most of the 63 "modules" are tier-2 consumers whose contract is `task_*(rtdb)` + RTDB keys + printed output.
   - The wide library APIs sit in tier 3 (NWints, basis, geom, symmetry), and each is documented.
   - Details in [nwchem-structure.md](nwchem-structure.md).
4. **For each unit:**
   1. Freeze its interface as a contract.
   2. Rewrite the unit in C++/Kokkos.
   3. Fortran callers that remain link through a generated `iso_c_binding` shim. The shim is deleted when its last Fortran caller is gone.
   4. External APIs are kept permanently: input deck, printed output, RTDB, Python module, socket driver, and the link-level symbols ChemShell uses.
5. **Extend NWChem's existing GNU make build** with a Kokkos option. Never generate a new build system: ParEval-Repo finds build generation is the main reason repo-level translation fails.
6. **Three gates per commit:**
   - **API:** callers compile, link and run with zero source edits, *including downstream projects*. **Printed output is part of the API**, because ASE, QCEngine and pymatgen parse it with regexes.
   - **Regression:** NWChem's QA suite at its own tolerances, plus our L0 differential tests and L3 downstream workflows. Bit-for-bit on the serial CPU backend where achievable.
   - **Performance:** time-to-solution, Kokkos-OpenMP vs Fortran/OpenMP on CPU, and Kokkos-CUDA on A100/H100.
7. **Code we do not translate:**
   - blas, lapack, 64to32blas and peigs (214k lines) are replaced by vendor BLAS/LAPACK/ScaLAPACK or Kokkos-Kernels.
   - Generated code (tce 3.2M lines; nwxc, Maxima-generated) is produced by **retargeting its generator**.
   - GA and MA are already C libraries and stay.
8. **Tests are not ported first.** NWChem's QA suite runs the binary, so it doesn't depend on the source language. Fortran test drivers stay as API consumers until after their unit is ported. Before porting a unit we **add** tests. The frozen baseline (`deps/nwchem`) is the oracle. Details in [testing.md](testing.md).
9. **Four people work in four lanes.**
   - Because each unit keeps its interface, a caller and its callee can be ported in parallel.
   - Lanes conflict only on shared files (build files, common blocks, `.fh` includes). Each of those has exactly one owner, and all build changes go through Lane A.
   - One unit = one branch = one PR, merged only when all gates pass.
10. **We report agent cost and effort per unit:** tokens, dollars, E_k (from ParEval-Repo), and the number of human interventions. For Phase 4, this gives the porting rate we extrapolate from.

## Open items / TODO
- [ ] **Where does the port live?** Options:
  - (a) a fork of NWChem added here as a second submodule;
  - (b) this repo becomes the fork.

  `deps/nwchem` stays the untouched baseline either way.
- [ ] Get the ChemShell source and extract the NWChem symbols and ABI it links against (`USE_64TO32=y`, integer width). See [downstream.md](downstream.md).
- [ ] Confirm which output fields the ASE, QCEngine and pymatgen parsers read, and turn them into an output-format contract.
- [ ] Check whether nwxc can be fully regenerated from `src/nwxc/maxima` and TCE from its generator.
- [ ] Build the baseline on our cluster. Record the QA pass rate, known failures and timings before any change.
- [ ] Assign people to lanes. This fills "Division of Work" in the proposal.
