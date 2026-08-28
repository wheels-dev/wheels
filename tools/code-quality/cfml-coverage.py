#!/usr/bin/env python3
"""
Function-level coverage for CRAP scores.

Wheels' TestBox coverage service is a no-op stub, so real coverage has to come
from source instrumentation. This tool:

  1. `instrument` — inserts a coverage counter at the top of every function
     body under a source root (writing `application.__wheels_cov[<id>] = true`),
     backing up the originals so `revert` restores them exactly.
  2. After you run the test suite and dump `application.__wheels_cov` to JSON,
     `combine` joins it with per-function complexity (cfml-complexity.py) and
     emits a CRAP ranking.
  3. `revert` — restores the original (uninstrumented) sources.

Usage:
  python3 cfml-coverage.py instrument vendor/wheels
  # ... run the suite, dump application.__wheels_cov to coverage.json ...
  python3 cfml-coverage.py combine vendor/wheels coverage.json complexity.json --coverage 100
  python3 cfml-coverage.py revert vendor/wheels
"""
import os, re, sys, json, shutil, argparse

SCRIPT_FN = re.compile(r'\bfunction\s+([A-Za-z_$][\w$]*)\s*\([^)]*\)\s*\{', re.S)
TAG_FN = re.compile(r'(<cffunction\b[^>]*?\bname\s*=\s*["\']?[A-Za-z_$][\w$]*[^>]*?>)', re.I)
EXCLUDE_DIRS = {'tests', 'rocketunit_tests'}


def _backup_dir(root):
    """Sibling of the instrumented root, so the walk never re-instruments it."""
    return os.path.join(os.path.dirname(os.path.abspath(root)), '.cfml-cov-backup')

COUNTER = '<cfset application.__wheels_cov["{id}"] = true>'
SCRIPT_COUNTER = '{counter} '   # inline after the opening brace


def _files(root):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIRS]
        for fn in filenames:
            if fn.lower().endswith(('.cfc', '.cfm')):
                yield os.path.join(dirpath, fn)


def _rel(path, root):
    return os.path.relpath(path, root)


def instrument(root):
    n = 0
    for path in _files(root):
        with open(path, encoding='utf-8', errors='replace') as fh:
            text = fh.read()
        rel = _rel(path, root)
        # script functions: insert counter right after the opening brace
        out = text
        for m in reversed(list(SCRIPT_FN.finditer(text))):
            brace = m.end()  # position just after '{'
            ctr = COUNTER.format(id=f"{rel}:{m.group(1)}")
            out = out[:brace] + ctr + out[brace:]
            n += 1
        # tag functions: insert counter right after the opening tag
        for m in reversed(list(TAG_FN.finditer(out))):
            ctr = COUNTER.format(id=f"{rel}:{m.group(1)}")
            out = out[:m.end()] + ctr + out[m.end():]
            n += 1
        if out != text:
            backup = os.path.join(_backup_dir(root), rel)
            os.makedirs(os.path.dirname(backup), exist_ok=True)
            shutil.copy2(path, backup)
            with open(path, 'w', encoding='utf-8') as fh:
                fh.write(out)
    print(f'instrumented {n} functions under {root} (backup in {_backup_dir(root)}/)')


def revert(root):
    n = 0
    for path in _files(root):
        rel = _rel(path, root)
        backup = os.path.join(_backup_dir(root), rel)
        if os.path.exists(backup):
            shutil.copy2(backup, path)
            n += 1
    print(f'reverted {n} files under {root}')


def crap(comp, cov):
    return (comp ** 2) * ((1 - cov / 100.0) ** 3) + comp


def combine(root, coverage_path, complexity_path):
    cov = json.load(open(coverage_path))
    complexity = {r['id']: r['complexity'] for r in json.load(open(complexity_path))}
    # cov keys are "<rel>:<fn>"; complexity ids are "<rel>:<line>:<fn>"
    rows = []
    for cid, comp in complexity.items():
        covered = cid in cov
        cv = 100.0 if covered else 0.0
        rows.append({'id': cid, 'complexity': comp, 'covered': covered, 'crap': round(crap(comp, cv), 1)})
    # rank uncovered complex functions first (highest risk)
    rows.sort(key=lambda r: (-r['crap'], -r['complexity']))
    print(f'{"CRAP":>7}  {"comp":>4}  cov  id')
    for r in rows[:50]:
        print(f'{r["crap"]:7.1f}  {r["complexity"]:4d}  {"yes" if r["covered"] else "no ":>3}  {r["id"]}')
    n_cov = sum(1 for r in rows if r['covered'])
    print(f'\nfunction coverage: {n_cov}/{len(rows)} ({100*n_cov/max(1,len(rows)):.1f}%)')
    json.dump(rows, open('crap-report.json', 'w'), indent=2)
    print('wrote crap-report.json')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=['instrument', 'revert', 'combine'])
    ap.add_argument('root')
    ap.add_argument('coverage_json', nargs='?', default=None)
    ap.add_argument('complexity_json', nargs='?', default=None)
    args = ap.parse_args()

    if args.cmd == 'instrument':
        instrument(args.root)
    elif args.cmd == 'revert':
        revert(args.root)
    elif args.cmd == 'combine':
        if not args.coverage_json or not args.complexity_json:
            ap.error('combine needs <coverage.json> <complexity.json>')
        combine(args.root, args.coverage_json, args.complexity_json)


if __name__ == '__main__':
    main()
