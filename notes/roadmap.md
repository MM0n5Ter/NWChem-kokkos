# Roadmap: from pilot to the whole repository

The target is the **whole repository** Fortran-free ([decisions.md](decisions.md) #2). Four people work in four lanes ([decisions.md](decisions.md) #9).

## Rules for parallel work
- Each unit keeps its interface, so a lane porting a caller never waits for the callee's port, and the reverse.
- Lanes conflict only on shared files: build files, common blocks and `.fh` includes. Each shared file has exactly one owner. Lane A owns the build.
- One unit = one branch = one PR. The main branch always builds and passes L1 and L2. A unit merges only when all three gates pass.
- Every unit has a **unit card**:
  - its files;
  - the document its contract comes from;
  - its internal callers;
  - the downstream consumers that touch it;
  - its L0–L3 tests;
  - owner and status;
  - agent cost (tokens, $, E_k) and human interventions.

## Phase 0: foundations (four lanes, no dependencies between them)
| Lane | Work |
|---|---|
| A: Build | Build the baseline, and the module subsets as in CI. Add a Kokkos option to `src/config/makefile.h` / GNU make. Link a toy C++ routine behind a Fortran shim end-to-end. |
| B: Contracts | Contract extractor: documentation (`api.doc`, `int_api_spec.tex`, …) + source signatures + common blocks/`.fh` → JSON. Shim generator (`iso_c_binding`). |
| C: Tests | QA runner wrapper. gcov coverage map (QA test → file → unit). Baseline L2 results and timings. L0 differential-harness template. |
| D: Downstream | Consumer registry ([downstream.md](downstream.md)). Run the ChemShell, ASE, QCEngine and Python workflows on the baseline and record reference results. Extract ChemShell's symbol list. |

**Exit:**
- baseline L2/L3 results recorded;
- coverage map exists;
- contract and shim generated for the NWints 1e unit;
- the Kokkos toy links.

## Phase 1: pilot on the NWints 1-electron integrals (the whole team on one unit)
- Scope: `int_1eov/ke/pe/h1/all` → `NWints/hondo` + `NWints/int`, about 10–15k lines.
- Why this unit:
  - it has a documented spec;
  - it depends only on infrastructure;
  - every SCF/DFT test exercises it;
  - it has few direct callers, so the API surface is small.
- Each lane runs its own tool on this unit. The agent does the translation. Afterwards: a retrospective, then fix the tools.
- Also run the kernel-level workflow of Gupta et al. on the same unit, as the comparison point.

**Exit:** all three gates pass, `small_intchk` and the covering QA subset pass, and the cost per kLOC is recorded.

## Phase 2: scale out to small targets (four independent lanes)
| Lane | Units |
|---|---|
| A | NWints 4-center ERIs: `int_2e4c`, `int_l2e4c` (Texas + McMurchie–Davidson), Schwarz screening. The widest fan-in (48 files / 11 modules), so the hardest API-gate test. |
| B | NWints `int_2e3c`/`int_2e2c` (RI/CD fitting), derivatives `intd_*`, ECP, relativistic/DK |
| C | DFT grid (`nwdft/grid`) + XC: regenerate `nwxc` from its Maxima sources instead of translating it |
| D | Tier-3 data libraries: basis, geom, symmetry, bq. Switch blas/lapack/peigs to vendor libraries. Nightly L3 runs. |

**Exit:** NWints is entirely C++ (only the Fortran shim remains), and its 119 caller files compile unchanged.

## Phase 3: large target, the SCF/DFT path (the paper's main result)
| Lane | Units |
|---|---|
| A | `ddscf` Fock build (`fock_2e*`, `ao_fock_2e`) and the SCF driver |
| B | `nwdft`: `scf_dft`, Coulomb/CD fitting, XC quadrature |
| C | gradients, hessian, cphf (analytic derivatives) |
| D | Performance evaluation: CPU Kokkos-OpenMP vs Fortran/OpenMP, GPU A100/H100 scaling. Ablations without the contract and without regression gating. L3 runs. |

**Exit:** `task energy` and `task gradient` for SCF and DFT have no Fortran below the task layer. Performance report done.

## Phase 4: the rest of the repository (waves in dependency order, one family per lane)
1. **QM extensions:** property, solvation (COSMO), dimqm, esp, dplot, moints, and the nwdft sub-modules (lr_tddft, rt_tddft, so_dft, zora, x2c).
2. **Correlated methods:** rimp2, mp2_grad, ccsd, mcscf, selci, mrpt, gwmol, bsemol, … Then the modules outside the default build: lucia, rdmft, uccsdt, nwc_columbus.
3. **Drivers and operations:** driver, optim, stepper, vib, cons, qmd, drdy, vscf, etrans, … These are thin, with mostly the `task_*`/RTDB contract.
4. **MM and QM/MM:** nwmd, qmmm, prepar, cafe, space, analyz, then argos and smd. ChemShell L3 runs on every merge.
5. **Special tracks:**
   - **tce:** retarget the generator, and keep the existing CUDA/OpenACC `ccsd_t` kernels as the comparison.
   - **nwpw:** its own pilot, behind `doc/plnwv_API.tex` and the socket driver.
6. **Last:** util, inp, rtdb, task, input, and the Python module glue. Delete the remaining shims. GA and MA stay.

## Realistic scope
- Phases 0–3 are what we deliver and evaluate.
- For Phase 4, we report the **rate** measured in Phases 1–3 (kLOC per week per lane, $ per kLOC, interventions per unit) and project the cost of the remaining ~2M hand-translated lines plus the two generators.
