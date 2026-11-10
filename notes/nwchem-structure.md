# NWChem structure: what the units of work are

Measured on `deps/nwchem` @ `be3ca06d`:
- **5.92M lines of Fortran** in `src/` (`scripts/loc-by-module.sh`), plus about 0.1M of C/C++;
- 87 top-level directories.

## The "63 modules" are not the right units
- The 63 are `KNOWN_MODULE_SUBDIRS` in `src/config/make_nwchem_config`, the optional feature modules of the build. The shared libraries (`util`, `geom`, `basis`, `inp`, `rtdb`, `symmetry`, `task`, `blas`/`lapack`, …) are not in that list.
- One directory can hold several units. `NWints`, for example, has the 1e, 2e4c, 2e3c/2e2c, derivative, ECP and relativistic sub-APIs.
- One unit can span directories. The Fock build, for example, spans `ddscf` and `nwdft/coulomb`.

## NWChem's own architecture (`doc/prog/nwarch.tex`)

| Tier | Examples | Its API | Where the API is documented |
|---|---|---|---|
| 1 Generic task interface | `task`, `task_energy(rtdb)`, `task_gradient(rtdb)` | `task_*(rtdb)` | `doc/prog/generic.tex` |
| 2 Calculation modules | ddscf, nwdft, mp2, ccsd, … (most of the 63) | **Only** `task_*` + RTDB keys. The guide says they "share data only through a disk-resident data base". | `doc/user/*.tex` (input blocks) |
| 3 Modeling tools | NWints, basis, geom, symmetry, bq, DFT grid | Wide Fortran APIs with many callers | `src/NWints/api/api.doc`, `doc/prog/int_api_spec.tex`, `basis.doc`, `geom.doc`, `doc/prog/symmetry.tex` |
| 4 Software development toolkit | GA, MA, ChemIO | Already C libraries; **kept** | `doc/prog/ga.tex`, `ma.tex` |
| 5 Utilities | util, inp, rtdb, pstat | Many small routines | `src/inp/inp.doc`, `src/rtdb/rtdb.doc`, `doc/prog/util.tex` |

**Consequences**
- Tier-2 modules are API *consumers*. Their contract is small: the `task_*` entry points, the RTDB keys they read and write, and the output they print.
- The library contracts sit in tier 3, and each is documented. These documents are the input specs for the contract extractor.
- The plane-wave code (`nwpw`) has its own API document, `doc/plnwv_API.tex`.

## Fan-in of the main tier-3 API
Callers outside `NWints/`, from `scripts/api-callers.sh`:

| Entry point | Files | Modules |
|---|---|---|
| `int_init` | 119 | 27 |
| `int_2e4c` | 48 | 11: ccsd ddscf develop etrans moints mp2_grad ncc nwc_columbus rdmft tce util |
| `int_2e3c` | 8 | 5: bsemol ddscf gwmol nwdft rimp2 |
| `intd_1eh1` | 7 | 6: develop gradients hessian nwc_columbus nwdft tce |
| `int_1eov` | 8 | 4: ddscf develop rdmft util (mostly through `ddscf/int_1e_ga.F`) |

Most-called modules from `scripts/xdeps.py --top 12` (fan-in = number of other modules that call in). Routine names defined in more than one module are skipped, which is why the BLAS/LAPACK copies drop out of the list:

| Module | fan_in | fan_out | Routines called from outside |
|---|---|---|---|
| util | 73 | 21 | 221 |
| geom | 59 | 11 | 125 |
| inp | 54 | 1 | 30 |
| ddscf | 41 | 24 | 117 |
| NWints | 39 | 16 | 175 |
| basis | 37 | 7 | 76 |
| symmetry | 31 | 11 | 39 |
| task | 24 | 55 | 17 |
| nwdft | 23 | 27 | 107 |

`ddscf` has high fan-in because it holds shared SCF helpers as well as the SCF module itself, so it is partly a tier-3 library. Callers outside `ddscf/` (`scripts/api-callers.sh -o ddscf`):
- `int_1e_ga`: 59 files, 14 modules;
- `movecs_read`: 49 files, 21 modules;
- `fock_2e`: 33 files, 6 modules.

These helpers are units with their own contracts, separate from the SCF driver.

## Every directory, sorted into buckets

| Bucket | Directories | Fortran lines | Treatment |
|---|---|---|---|
| **Vendor-replace** | blas, lapack, 64to32blas, peigs, peigs_comm | 214k | Not translated. Use vendor BLAS/LAPACK/ScaLAPACK or Kokkos-Kernels. |
| **Generated** | tce (3.2M); nwxc (457k, 46 of 81 files reference Maxima) | 3,658k | Retarget the generator to emit C++/Kokkos |
| Infrastructure (tiers 1, 5) | util, inp, input, rtdb, pstat, perfm, task, python | 53k | Ported last. Fortran callers keep using it through shims until then. |
| **Tier-3 libraries** | NWints, basis, geom, symmetry, bq, fft | 173k | Pilot and small targets |
| SCF/DFT path | ddscf, nwdft, atomscf, gradients, hessian, cphf, property, solvation, dimqm, esp, dplot, moints | 407k | Large target |
| Correlated methods | rimp2, mp2_grad, rimp2_grad, ccsd, mcscf, selci, mrpt, uccsdt, ccca, ncc, cckohn, fcidump, gwmol, bsemol, lucia (287k), rdmft, nwc_columbus | 450k | Phase-4 wave |
| Drivers and operations | driver, optim, stepper, vib, cons, drdy, qmd, vscf, etrans, dntmc, leps, qhop, dangchang | 82k | Phase-4 wave (mostly control logic) |
| MM and QM/MM | nwmd, qmmm, prepar, argos, cafe, space, analyz, diana, mm, rism, smd, xtb, chelp | 294k | Phase-4 wave (ChemShell depends on QM/MM) |
| Plane wave | nwpw | 560k | Separate track behind its own API |
| Development and other | develop, geninterface, cca | 31k | `develop` is mostly test drivers (see [testing.md](testing.md)) |

- Code we translate ourselves is **about 2.05M lines**: the total minus the vendor-replace and generated buckets.
- The default `NWCHEM_MODULES=all` build already excludes argos, leps, smd, uccsdt, python, develop, rimp2_grad, geninterface, diana, nbo, rism, lucia, nwxc, rdmft, xtb and nwc_columbus (`EXP_all` in `make_nwchem_config`). Those go late in their waves.
- Existing GPU code is only in `tce/ccsd_t` and `tce/ttlg` (CUDA), plus OpenACC/OpenMP-target in `tce/ccsd_t` and `ccsd`.
