#!/usr/bin/env python3
"""
Function-level coverage for CRAP scores.

Wheels' TestBox coverage service is a no-op stub, so real coverage has to come
from source instrumentation. This tool:

  1. `instrument` — inserts a coverage counter at the top of every function
     body under a source root (writing `server.__wheels_cov[<id>] = true`),
     backing up the originals so `revert` restores them exactly.
  2. After you run the test suite and dump `server.__wheels_cov` to JSON,
     `combine` joins it with per-function complexity (cfml-complexity.py) and
     emits a CRAP ranking.
  3. `revert` — restores the original (uninstrumented) sources.

Usage:
  python3 cfml-coverage.py instrument vendor/wheels
  # ... run the suite, dump server.__wheels_cov to coverage.json ...
  python3 cfml-coverage.py combine vendor/wheels coverage.json complexity.json
  python3 cfml-coverage.py revert vendor/wheels
"""
import os, re, sys, json, shutil, argparse

SCRIPT_FN = re.compile(r'\bfunction\s+([A-Za-z_$][\w$]*)\s*\([^)]*\)\s*\{', re.S)
# Guarded closure assignments (include-idempotent templates):
#   variables.$helper = function(args) { ... };
CLOSURE_FN = re.compile(r'\bvariables\s*\.\s*\$?([A-Za-z_$][\w$]*)\s*=\s*function\s*\([^)]*\)\s*\{', re.S)
# Capture the name only (group 1); the opening tag itself is not part of the id —
# embedding it produced ids full of quotes, i.e. invalid CFML in the counter.
TAG_FN = re.compile(r'<cffunction\b[^>]*?\bname\s*=\s*["\']?([A-Za-z_$][\w$]*)', re.I)
EXCLUDE_DIRS = {'tests', 'rocketunit_tests'}

DSTRING = re.compile(r'"(?:[^"\\]|\\.)*"', re.S)
SSTRING = re.compile(r"'(?:[^'\\]|\\.)*'", re.S)
LINE_COMMENT = re.compile(r'//[^\n]*')
BLOCK_COMMENT = re.compile(r'/\*.*?\*/', re.S)
TAG_COMMENT = re.compile(r'<!---.*?--->', re.S)


def _mask(text):
    """Mask strings and comments with same-length spaces so function patterns
    never match inside them (JS `function name(){` in a CFML string literal
    used to get a counter inserted mid-string — a parse error). Offsets are
    preserved, so matches map back onto the original text unchanged."""
    for pat in (DSTRING, SSTRING, LINE_COMMENT, BLOCK_COMMENT, TAG_COMMENT):
        text = pat.sub(lambda m: ' ' * len(m.group(0)), text)
    return text


def _backup_dir(root):
    """Sibling of the instrumented root, so the walk never re-instruments it."""
    return os.path.join(os.path.dirname(os.path.abspath(root)), '.cfml-cov-backup')

# CFScript components (the .cfc files) use script syntax — no tags inside a
# function body. Tag-based .cfm/.cfc use <cfset>. Both are self-initializing.
# server scope is process-wide and is not iterated by request-scope-sensitive
# middleware/rate-limiter code, unlike request scope.
SCRIPT_COUNTER = ('server.__wheels_cov = isDefined("server.__wheels_cov")'
                  ' ? server.__wheels_cov : {{}};'
                  ' server.__wheels_cov["{id}"] = true;')
TAG_COUNTER = ('<cfset server.__wheels_cov = isDefined("server.__wheels_cov")'
               ' ? server.__wheels_cov : {{}}><cfset server.__wheels_cov["{id}"] = true>')


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
        masked = _mask(text)
        # Collect every insertion point against the original (masked) offsets
        # first, then apply them right-to-left so earlier insertions never
        # shift later positions.
        matches = []
        for pat in (SCRIPT_FN, CLOSURE_FN):
            for m in pat.finditer(masked):
                matches.append((m.end(), 'script', m.group(1)))
        for m in TAG_FN.finditer(masked):
            brace = masked.find('>', m.end())
            if brace >= 0:
                matches.append((brace + 1, 'tag', m.group(1)))
        matches.sort(key=lambda t: -t[0])
        out = text
        for pos, kind, name in matches:
            ctr = (SCRIPT_COUNTER if kind == 'script' else TAG_COUNTER).format(id=f"{rel}:{name}")
            out = out[:pos] + ctr + out[pos:]
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


def _cov_key(complexity_id):
    """Map complexity id 'rel:line:function' -> coverage key 'rel:function'."""
    rel_line, function = complexity_id.rsplit(':', 1)
    rel = rel_line.rsplit(':', 1)[0]
    return f"{rel}:{function}"


def combine(root, coverage_path, complexity_path):
    cov = json.load(open(coverage_path))
    raw_complexity = json.load(open(complexity_path))
    if isinstance(raw_complexity, dict):
        # cfml-complexity.py --baseline write emits {id: complexity}
        complexity = {rid: int(comp) for rid, comp in raw_complexity.items()}
    else:
        # --json emits a list of rows with id/complexity
        complexity = {r['id']: int(r['complexity']) for r in raw_complexity}
    # cov keys are "<rel>:<fn>"; complexity ids are "<rel>:<line>:<fn>"
    rows = []
    for cid, comp in complexity.items():
        covered = _cov_key(cid) in cov
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
