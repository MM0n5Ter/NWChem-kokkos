# Downstream: who builds on NWChem, and what that freezes

The API gate must protect every consumer, not only NWChem's internal callers. A downstream project is one that builds its own science on NWChem, such as a QM/MM code, an MD driver or a workflow engine. What it touches defines **which surfaces are frozen**. Running its real workflows unchanged is our top test level (L3, see [testing.md](testing.md)).

## Consumers

| Consumer | How it couples to NWChem | Surface it freezes | Status |
|---|---|---|---|
| **ChemShell** (Tcl and Py-ChemShell, QM/MM) | **Links NWChem in as a library** (requires `USE_64TO32=y`). Also has a file-based mode. | Link-level symbols and ABI (task, rtdb, geom, bq point charges), integer width | Linking verified from the [ChemShell docs](https://chemshell.org/static_files/tcl-chemshell/manual/nwchem_print.html). **The symbol list must be extracted from ChemShell's source.** |
| ASE `NWChem` calculator | Writes the input deck, parses the printed output | Input keywords, printed output lines | *(verify against ASE source)* |
| ASE `SocketIOCalculator`, i-PI | Socket using the i-PI protocol (`src/driver/socket_driver.F`, `driver` input block; `nwpw/pspw/cpsd/runsocket.F`) | Socket protocol; energies, forces and stress | NWChem is listed as a client in the [ASE socket docs](https://docs.ase-lib.org/ase/calculators/socketio/socketio.html) |
| QCEngine / QCFractal (MolSSI) | NWChem harness: writes input, parses output | Input keywords, printed output lines | Harness exists ([changelog](https://molssi.github.io/QCEngine/changelog.html)). *(verify which fields it parses)* |
| pymatgen `io.nwchem` | Input writer and output parser | Same as above | *(verify)* |
| User scripts using the NWChem Python module | `task_energy`, `task_gradient`, `rtdb_get/put`, `input_parse`, `pgroup_*`, … (`src/python/nwchem_wrap.c`) | The Python module API | In repo |

## Takeaways
1. **Printed output is part of the API.** ASE, QCEngine and pymatgen read it with regexes. A port that reformats a line such as `Total DFT energy =` breaks them even though every Fortran signature is preserved. The API gate diffs the *labels and layout* of the output lines these parsers read, not only the numbers.
2. **ChemShell is the one link-level library consumer.** Its symbols, the ABI and the integer width go into the contract. Its QM/MM workflow is the strongest end-to-end API test, and it is why the QM/MM wave needs L3 on every merge.
3. **The external contract** is the union of the input deck, the parsed output fields, the RTDB keys, the Python module, the socket protocol and ChemShell's symbols. It never changes, even after the last shim is gone.

## Consumer registry (Phase 0, Lane D)
For each consumer, record:
- its version;
- its coupling mode;
- the exact symbols, keywords, RTDB keys and output fields it touches;
- one or more real workflows (inputs + reference results from the frozen baseline);
- how to run them with zero edits to the consumer.
