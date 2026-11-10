#!/usr/bin/env python3
"""Cross-module call graph of NWChem's Fortran (regex-based, approximate).

A "module" is a top-level directory under src/. For each module this script
reports its fan-in (how many other modules call into it), its fan-out (how
many modules it calls), and how many of its routines are called from outside.

It only finds routines defined with `subroutine` or `function`. A name that
two or more modules define is skipped as ambiguous (examples: dfill,
errquit). Results are approximate and good for ranking, not exact counts.

Usage: scripts/xdeps.py [NWCHEM_SRC] [--json OUT] [--top N]
       (default NWCHEM_SRC: deps/nwchem/src)
"""
import argparse, collections, json, os, re

EXT = ('.F', '.f', '.f90', '.F90')
DEF = re.compile(r'^\s*(?:(?:recursive|pure|elemental|integer|logical|'
                 r'double\s+precision|real(?:\*8)?|character\*?\(?\*?\)?|'
                 r'complex(?:\*16)?)\s+)*(?:subroutine|function)\s+([a-z_]\w*)', re.I)
USE = re.compile(r'\b([a-z_]\w*)\s*\(', re.I)


def fortran_lines(path):
    with open(path, errors='ignore') as fh:
        for line in fh:
            if line[:1] not in 'cC*!':
                yield line


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    ap = argparse.ArgumentParser()
    ap.add_argument('src', nargs='?', default=os.path.join(here, '..', 'deps', 'nwchem', 'src'))
    ap.add_argument('--json')
    ap.add_argument('--top', type=int, default=0)
    a = ap.parse_args()

    files = collections.defaultdict(list)
    for mod in sorted(os.listdir(a.src)):
        p = os.path.join(a.src, mod)
        if os.path.isdir(p):
            for dp, _, fs in os.walk(p):
                files[mod] += [os.path.join(dp, f) for f in fs if f.endswith(EXT)]

    owners = collections.defaultdict(set)
    for mod, fl in files.items():
        for f in fl:
            for line in fortran_lines(f):
                m = DEF.match(line)
                if m:
                    owners[m.group(1).lower()].add(mod)
    defs = {n: next(iter(m)) for n, m in owners.items() if len(m) == 1}

    fan_in, fan_out = collections.defaultdict(set), collections.defaultdict(set)
    exported = collections.defaultdict(set)
    edges = collections.Counter()
    for mod, fl in files.items():
        for f in fl:
            for line in fortran_lines(f):
                for n in USE.findall(line):
                    d = defs.get(n.lower())
                    if d and d != mod:
                        fan_in[d].add(mod); fan_out[mod].add(d)
                        exported[d].add(n.lower()); edges[(mod, d)] += 1

    mods = sorted(set(files), key=lambda m: (-len(fan_in[m]), m))
    if a.top:
        mods = mods[:a.top]
    print(f"{'module':16s} {'fan_in':>6s} {'fan_out':>7s} {'exported':>8s}")
    for m in mods:
        print(f"{m:16s} {len(fan_in[m]):6d} {len(fan_out[m]):7d} {len(exported[m]):8d}")
    if a.json:
        with open(a.json, 'w') as fh:
            json.dump({'edges': [[x, y, c] for (x, y), c in edges.items()],
                       'exported': {k: sorted(v) for k, v in exported.items()}}, fh)


if __name__ == '__main__':
    main()
