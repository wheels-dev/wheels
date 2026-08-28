#!/usr/bin/env python3
"""
CFML cyclomatic-complexity analyzer + deterministic quality gate.

Computes McCabe cyclomatic complexity per function across a CFML codebase,
handling both CFScript (`if/for/while/case/catch/&&/||/?:`) and tag
(`<cfif>/<cfloop>/<cfcase>/<cfcatch>`) syntax, and computes a CRAP score:
    CRAP = comp^2 * (1 - cov/100)^3 + comp

Modes:
  report                     print a summary + hotspots (default)
  --baseline write           dump {file:function:line -> complexity} JSON
  --gate N --baseline F      fail (exit 1) if any function exceeds N that is
                             new (absent from baseline) or regressed (complexity
                             grew vs baseline). Existing hotspots pass; functions
                             are matched by name (file:function), so edits that
                             shift line numbers elsewhere in a file are fine.

Usage:
  python3 cfml-complexity.py [root] --top 40
  python3 cfml-complexity.py vendor/wheels --baseline write > baseline.json
  python3 cfml-complexity.py vendor/wheels --gate 30 --baseline baseline.json
"""
import os, re, sys, json, argparse, statistics
from collections import defaultdict

TAG_COMMENT = re.compile(r'<!---.*?--->', re.S)
BLOCK_COMMENT = re.compile(r'/\*.*?\*/', re.S)
LINE_COMMENT = re.compile(r'(?<!:)//[^\n]*')
DSTRING = re.compile(r'"(?:[^"\\]|\\.)*"')
SSTRING = re.compile(r"'(?:[^'\\]|\\.)*'")

SCRIPT_DECISION = re.compile(
    r'\bif\b|\belseif\b|\belse\s+if\b|\bfor\b|\bwhile\b|\bdo\b'
    r'|\bcase\b|\bcatch\b|\band\b|\bor\b|&&|\|\||\?'
)
TAG_DECISION = re.compile(r'<cf(if|elseif|loop|while|case|defaultcase|catch)\b', re.I)

SCRIPT_FN = re.compile(r'\bfunction\s+([A-Za-z_$][\w$]*)\s*\([^)]*\)', re.S)
TAG_FN = re.compile(r'<cffunction\b[^>]*?\bname\s*=\s*["\']?([A-Za-z_$][\w$]*)', re.I)

EXCLUDE_DIRS = {'tests', 'rocketunit_tests'}


def strip_comments(s):
    s = TAG_COMMENT.sub('', s)
    s = BLOCK_COMMENT.sub('', s)
    s = LINE_COMMENT.sub('', s)
    return s


def strip_strings(s):
    s = DSTRING.sub('""', s)
    s = SSTRING.sub("''", s)
    return s


def cyclomatic(body):
    b = strip_strings(strip_comments(body))
    return 1 + len(SCRIPT_DECISION.findall(b)) + len(TAG_DECISION.findall(b))


def crap(comp, cov):
    return (comp ** 2) * ((1 - cov / 100.0) ** 3) + comp


def _brace_body(text, open_idx):
    brace = text.find('{', open_idx)
    if brace < 0:
        return None
    depth, i = 0, brace
    while i < len(text):
        c = text[i]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                return text[brace:i + 1]
        i += 1
    return None


def extract_functions(text):
    out = []
    for m in SCRIPT_FN.finditer(text):
        body = _brace_body(text, m.start())
        if body is not None:
            out.append((m.group(1), body, text.count('\n', 0, m.start()) + 1))
    for m in TAG_FN.finditer(text):
        close = re.search(r'</cffunction\b', text[m.end():], re.I)
        if close:
            body = text[m.end():m.end() + close.start()]
            out.append((m.group(1), body, text.count('\n', 0, m.start()) + 1))
    return out


def analyze_file(path):
    with open(path, 'r', encoding='utf-8', errors='replace') as fh:
        text = fh.read()
    cleaned = strip_comments(text)
    funcs = extract_functions(cleaned)
    results = []
    for name, body, line in funcs:
        results.append({
            'file': path, 'function': name, 'line': line,
            'loc': body.count('\n') + 1, 'complexity': cyclomatic(body),
        })
    if not results:
        results.append({
            'file': path, 'function': '<template>', 'line': 1,
            'loc': cleaned.count('\n') + 1, 'complexity': cyclomatic(cleaned),
        })
    return results


def walk(root):
    rows = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIRS]
        for fn in filenames:
            if fn.lower().endswith(('.cfc', '.cfm')):
                try:
                    rows.extend(analyze_file(os.path.join(dirpath, fn)))
                except Exception as e:
                    print(f'WARN {fn}: {e}', file=sys.stderr)
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('root', nargs='?', default='vendor/wheels')
    ap.add_argument('--coverage', type=float, default=0.0)
    ap.add_argument('--top', type=int, default=40)
    ap.add_argument('--json', default=None)
    ap.add_argument('--baseline', default=None)
    ap.add_argument('--gate', type=int, default=None)
    args = ap.parse_args()

    rows = walk(args.root)
    for r in rows:
        r['rel'] = os.path.relpath(r['file'], args.root)
        r['id'] = f"{r['rel']}:{r['line']}:{r['function']}"
        r['crap'] = round(crap(r['complexity'], args.coverage), 1)

    # --baseline write
    if args.baseline == 'write':
        print(json.dumps({r['id']: r['complexity'] for r in rows}, indent=2, sort_keys=True))
        return

    # --gate N
    if args.gate is not None:
        baseline = {}
        if args.baseline and os.path.exists(args.baseline):
            baseline = json.load(open(args.baseline))
        # Match baseline entries by (file, function) rather than exact
        # file:line:function id: inserting lines elsewhere in a file shifts
        # every later function's line number, which used to make unchanged
        # over-threshold functions look "new" and fail the gate spuriously.
        # When a file defines several same-named functions, fall back to the
        # nearest line within LINE_WINDOW.
        LINE_WINDOW = 250
        bindex = defaultdict(list)
        for bid, bcomp in baseline.items():
            parts = bid.rsplit(':', 2)
            if len(parts) == 3:
                bfile, bline, bfn = parts
                try:
                    bindex[(bfile, bfn)].append((int(bline), bcomp))
                except ValueError:
                    pass
        violations = []
        for r in rows:
            if r['complexity'] > args.gate:
                prev = None
                cands = bindex.get((r['rel'], r['function']))
                if cands:
                    if len(cands) == 1:
                        prev = cands[0][1]
                    else:
                        nearest = min(cands, key=lambda c: abs(c[0] - r['line']))
                        if abs(nearest[0] - r['line']) <= LINE_WINDOW:
                            prev = nearest[1]
                if prev is None or r['complexity'] > prev:
                    violations.append(r)
        if violations:
            print(f'FAIL: {len(violations)} function(s) exceed complexity {args.gate} '
                  f'(new or regressed).')
            for r in sorted(violations, key=lambda x: -x['complexity']):
                print(f'  {r["complexity"]:3d}  {r["id"]}  (loc={r["loc"]})')
            sys.exit(1)
        print(f'PASS: no new/regressed functions over complexity {args.gate}.')
        return

    # report
    comps = [r['complexity'] for r in rows]
    comps_sorted = sorted(comps)
    def pct(p):
        if not comps_sorted:
            return 0
        return comps_sorted[min(len(comps_sorted) - 1, int(round(p / 100.0 * (len(comps_sorted) - 1))))]

    print(f'files={len({r["file"] for r in rows})} funcs={len(rows)} '
          f'loc={sum(r["loc"] for r in rows)}')
    if comps:
        print(f'complexity mean={statistics.mean(comps):.1f} median={statistics.median(comps):.1f} '
              f'p90={pct(90)} p95={pct(95)} max={max(comps)}')
        print(f'  <=10: {sum(1 for c in comps if c<=10)}  '
              f'11-20: {sum(1 for c in comps if 11<=c<=20)}  '
              f'21-50: {sum(1 for c in comps if 21<=c<=50)}  '
              f'>50: {sum(1 for c in comps if c>50)}')
    print(f'\n-- top {args.top} most complex --')
    for r in sorted(rows, key=lambda x: -x['complexity'])[:args.top]:
        print(f'  {r["complexity"]:3d}  {r["id"]}  (CRAP={r["crap"]})')

    if args.json:
        json.dump(rows, open(args.json, 'w'), indent=2)
        print(f'\nwrote {args.json}')


if __name__ == '__main__':
    main()
