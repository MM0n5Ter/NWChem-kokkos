# Landscape: agentic Fortran → C++/Kokkos translation

Read on 2026-11-08 from the papers themselves (PDFs by arXiv ID).

## Summary table

| Work | Level | What it does | How we differ |
|---|---|---|---|
| **Gupta et al.**, *From Legacy Fortran to Portable Kokkos* (arXiv:2509.12443, LANL) | Kernel | Multi-agent pipeline (translate, validate, build, run, test/fix, profiler-guided optimize), no human in the loop. GPT-5: 97% correct baseline, 80% complete the full workflow. About $2 per kernel. | Their stated future work is our scope: "whole applications with interconnected modules, global state, I/O and build systems". We reuse their agent roles and loop. |
| **Ren et al.**, *NICAM from Fortran to Kokkos* (arXiv:2610.41313) | Application, standalone | Claude Code ported about 140k Fortran lines to 35k C++/Kokkos lines, human-directed, module by module. 1.71× on GH200. | Standalone executable; namelists replaced by YAML. That breaks library users, which we cannot do. |
| **Koldunov et al.**, *FESOM2* (arXiv:2606.11356, AWI) | Application, standalone | Fortran → literal C → C++/Kokkos, about 74k lines, in weeks. Bit-for-bit on CPU backends, statistical agreement on GPU. | Standalone, with no API guarantee. We adopt their validation ladder and failure-mode checklist. |
| **Sadr et al.**, *ORB5X* (arXiv:2607.17363, EPFL) | Application, standalone | Gyrokinetic PIC code in C++17/Kokkos, routine by routine, human-reviewed. Agrees with ORB5 to near machine precision. | Standalone. We reuse their "translation audit list" and indexing/reduction rules. |
| **Lahlou et al.**, *Fortran → JAX land surface* (arXiv:2606.07681) | Application, dependency-ordered | 19k lines of CLM-ml translated to JAX: static dependency order, compile-repair loops, Fortran oracle per module, 73 module tasks. | Closest method to ours, but the target is JAX and the result is a new codebase. We borrow the leaves-first schedule and per-module oracles. |
| **Chen et al.**, *Fortran2CPP* (arXiv:2412.19770, LLNL) | Function | 11.7k dual-agent dialogues used to fine-tune open models. +92% compile success. | Serial, function-level, surface metrics only. Shows that compiling does not mean correct. |
| **Davis et al.**, *ParEval-Repo* (arXiv:2506.20938, ICPP'25) | Repo, benchmark | Whole-repo translation between CUDA, OpenMP offload and Kokkos. **pass@1 = 0 for every app above toy size.** Build systems are the main failure. Defines the E_k cost metric. | Main evidence that repo level is open. We extend the existing build and translate behind fixed interfaces. |
| **Ou et al.**, *RustRepoTrans* (arXiv:2411.13990, ASE'25) | Repo context | 375 incremental, in-repository function tasks → Rust, judged by the project's own tests. pass@1 drops 22 points with repository context. | Closest SE analogue (incremental, in-repo). We add an HPC target, an ABI-compatible language boundary and a performance gate. |
| **Aprà et al.**, *NWChem: Past, Present, and Future* (arXiv:2004.12023, JCP 2020) | Target system | NWChem overview: GA/ARMCI, TCE CCSD(T) on GPUs. NWChemEx is a separate ground-up C++ rewrite. | GPU code exists only in `tce/ccsd_t` and `tce/ttlg`. SCF, DFT and integrals are CPU-only. NWChemEx is a rewrite, not an API-preserving migration. |

## Lessons to reuse
- **Staged validation (FESOM2):**
  - bit-for-bit where achievable, statistical agreement otherwise;
  - run at the production configuration, not only a smoke test;
  - require identical output across MPI rank counts (this catches halo bugs).
- **Cite the Fortran (FESOM2):** any claim about what the Fortran does must cite the exact file and line, and the value read there. Latent-constant bugs (1e-9 written instead of 0.1) only blew up after about 110 simulated days.
- **Indexing and reductions (ORB5X):** make index offsets, Fortran bounds such as `0:N+1`, column-major vs Kokkos layout, and reduction order explicit rules. Have the agent emit an audit list per unit and turn it into tests.
- **Randomized oracle inputs (Gupta):** fixed inputs let "reward-hacking" code pass while computing less than the full kernel.
- **Plan and checkpoints (NICAM):** a progress file, human checkpoints, and component-level reference dumps.
- **Dependency-ordered schedule (Lahlou):** leaves first, with a module oracle before integration.

## Where we fit
1. Kernel-level automation works (Gupta).
2. Application-level ports are now feasible, but all of them are standalone rewrites (NICAM, FESOM2, ORB5X, Lahlou).
3. Repo-level automation still fails, mainly on build systems and cross-file context (ParEval-Repo, RustRepoTrans).
4. **Our gap:** *API-preserving, incremental, repository-level* Fortran → Kokkos migration of a code that is used as a library. Every step is gated by API, Regression and Performance checks.
