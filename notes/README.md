# Notes

These are working notes. Numbers were measured on `deps/nwchem` at `be3ca06d` with the scripts in `../scripts/`, unless a line is marked *(verify)*.

- [decisions.md](decisions.md): the story, design decisions and open TODOs
- [landscape.md](landscape.md): related work (kernel-level, application-level and repository-level agentic translation; NWChem itself) and where we fit
- [nwchem-structure.md](nwchem-structure.md): NWChem's five-tier architecture, units of work as API contracts, fan-in of the main APIs, and every directory in `src/` sorted into buckets
- [downstream.md](downstream.md): projects built on NWChem, how each one couples to it, and the API surface each one freezes
- [testing.md](testing.md): NWChem's existing tests, our test levels L0–L3, and why the tests are not ported first
- [roadmap.md](roadmap.md): Phases 0–4 to a Fortran-free repo, in four parallel lanes
