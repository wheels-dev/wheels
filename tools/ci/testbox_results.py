#!/usr/bin/env python3
"""Walk a TestBox JSON result and account for every failure it reports.

TestBox nests child suites under ``suiteStats`` at every level (older
reporters used ``nestedSuiteStats``), and a bundle that throws outside any
spec (``beforeAll``, a compile error, a missing fixture) reports it only as
the bundle's ``globalException``. A walker that reads just the first level
of suites misses both, so a run can print "N pass, 1 fail" and still exit 0
(#3694, and the RustCFML walker in #3687).

``walk()`` visits the whole tree. ``reconcile()`` compares what it found
with TestBox's own ``totalFail`` / ``totalError``; when they disagree,
neither number can be trusted and the caller must fail closed.

Used as a module (tools/rustcfml, tests) or from the command line:

    testbox_results.py RESULT.json [--policy cli] [--strict]

Exit codes: 0 = no gating failures and the counts reconcile,
1 = gating failures, 2 = unreadable or not a usable TestBox result (see
validate()), 3 = counts do not reconcile.
"""

import argparse
import json
import sys

DEPLOY_BUNDLE_PREFIX = "cli.lucli.tests.specs.deploy"


def _get(node, key, default=None):
    """Read a key case-insensitively (reporters differ: message/Message)."""
    if not isinstance(node, dict):
        return default
    if key in node:
        return node[key]
    lowered = key.lower()
    for k, v in node.items():
        if isinstance(k, str) and k.lower() == lowered:
            return v
    return default


def _exception_text(exc):
    if isinstance(exc, dict):
        return str(_get(exc, "message") or _get(exc, "detail") or exc)
    return str(exc)


def validate(result):
    """Return a list of reasons this is not a usable TestBox result (empty = OK).

    A gate that fails closed must not read an unrecognised document as "no
    failures": a JSON array, {}, a runner error envelope ({success: false}),
    totals with no bundle tree, a negative or missing total, and an empty run
    (no bundles, nothing executed) are all rejected (#3695 review).
    """
    if not isinstance(result, dict):
        return [f"expected a JSON object, got {type(result).__name__}"]
    problems = []
    if _get(result, "success") is False:
        detail = _get(result, "error") or _get(result, "message") or "no detail"
        problems.append(f"the runner reported failure (success: false): {detail}")
    bundles = _get(result, "bundleStats")
    if not isinstance(bundles, list):
        problems.append("missing bundleStats list")
    for key in ("totalPass", "totalFail", "totalError"):
        value = _get(result, key)
        # Adobe CF serialises the totals as floats (5792.0), so accept any
        # whole number; reject bools, fractions, strings and absence.
        whole = (
            not isinstance(value, bool)
            and isinstance(value, (int, float))
            and float(value).is_integer()
        )
        if not whole:
            problems.append(f"{key} is missing or not a whole number ({value!r})")
        elif value < 0:
            problems.append(f"{key} is negative ({value})")
    if not problems:
        executed = sum(int(_get(result, k)) for k in ("totalPass", "totalFail", "totalError"))
        if not bundles or executed == 0:
            problems.append("empty result: no bundles ran and no specs executed")
    return problems


def walk(result):
    """Return every failure in the result as a list of dicts.

    Each entry:
      kind     "Failed" | "Error" | "BundleError" | "Unknown" (any status that
               is not Passed/Skipped/Failed/Error — counted as failing)
      status   the raw spec status ("Exception" for a bundle error)
      bundle   bundle name
      path     suite names, outermost first, unmodified (list)
      path_text  the same joined with " > "
      name     spec name ("(bundle-level exception)" for a bundle error)
      message, detail  failMessage / failDetail (or the exception's), newlines kept
    """
    found = []

    def visit_suite(suite, bundle, trail):
        path = trail + [str(_get(suite, "name", "?"))]
        for spec in _get(suite, "specStats", []) or []:
            status = str(_get(spec, "status", "") or "")
            if status in ("Passed", "Skipped"):
                continue
            found.append({
                "kind": status if status in ("Failed", "Error") else "Unknown",
                "status": status,
                "bundle": bundle,
                "path": list(path),
                "path_text": " > ".join(path),
                "name": str(_get(spec, "name", "?")),
                "message": str(_get(spec, "failMessage") or ""),
                "detail": str(_get(spec, "failDetail") or ""),
            })
        # Both keys are read (older reporters used nestedSuiteStats). A
        # reporter that emitted the same children under both would be
        # counted twice; reconcile() then reports the mismatch (exit 3), so
        # a double emission fails closed rather than passing.
        for key in ("suiteStats", "nestedSuiteStats"):
            for child in _get(suite, key, []) or []:
                visit_suite(child, bundle, path)

    for bundle in _get(result, "bundleStats", []) or []:
        name = str(_get(bundle, "name", "?") or "?")
        exc = _get(bundle, "globalException")
        if exc:
            found.append({
                "kind": "BundleError",
                "status": "Exception",
                "bundle": name,
                "path": [],
                "path_text": "",
                "name": "(bundle-level exception)",
                "message": _exception_text(exc),
                "detail": str(_get(exc, "detail") or "") if isinstance(exc, dict) else "",
            })
        for suite in _get(bundle, "suiteStats", []) or []:
            visit_suite(suite, name, [])
    return found


def totals(result):
    return {
        "pass": int(_get(result, "totalPass", 0) or 0),
        "fail": int(_get(result, "totalFail", 0) or 0),
        "error": int(_get(result, "totalError", 0) or 0),
    }


def reconcile(result, failures):
    """Return a list of human-readable mismatches (empty when they agree).

    A bundle-level exception counts as one error, which is how TestBox
    totals it.
    """
    t = totals(result)
    failed = sum(1 for f in failures if f["kind"] == "Failed")
    errored = sum(1 for f in failures if f["kind"] in ("Error", "BundleError"))
    problems = []
    if failed != t["fail"]:
        problems.append(f"totalFail is {t['fail']} but {failed} failing spec(s) were found in the tree")
    if errored != t["error"]:
        problems.append(f"totalError is {t['error']} but {errored} error(s) were found in the tree")
    return problems


def is_gating(failure, strict):
    """CLI policy: deploy bundles always gate; everything gates in strict mode.
    A status the walker doesn't recognise always gates (fail closed)."""
    return strict or failure["kind"] == "Unknown" or failure["bundle"].startswith(DEPLOY_BUNDLE_PREFIX)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("result")
    parser.add_argument("--strict", action="store_true", help="every failure gates")
    parser.add_argument("--json", action="store_true", help="print the failure list as JSON")
    args = parser.parse_args(argv)

    try:
        with open(args.result, encoding="utf-8") as fh:
            result = json.load(fh)
    except Exception as exc:  # noqa: BLE001 - any unreadable result is fatal
        print(f"Failed to parse results: {exc}")
        return 2

    invalid = validate(result)
    if invalid:
        print("NOT A TESTBOX RESULT — refusing to certify this run:")
        for p in invalid:
            print(f"  {p}")
        print(f"Raw result: {args.result}")
        return 2

    failures = walk(result)
    if args.json:
        print(json.dumps(failures, indent=2))

    t = totals(result)
    print(f"{t['pass']} pass, {t['fail']} fail, {t['error']} error")

    gating = 0
    nongating = 0
    for f in failures:
        gates = is_gating(f, args.strict)
        prefix = "  " if gates else "  [non-gating] "
        where = f" > {f['path_text']}" if f["path_text"] else ""
        print(f"{prefix}{f['kind']}: {f['bundle']}{where}: {f['name']}: {f['message'].replace(chr(10), ' | ')[:180]}")
        if gates:
            gating += 1
        else:
            nongating += 1

    problems = reconcile(result, failures)
    if problems:
        print("\nCOUNTS DON'T RECONCILE — refusing to trust this result:")
        for p in problems:
            print(f"  {p}")
        print(f"Raw result: {args.result}")
        return 3

    if nongating and not args.strict:
        print(f"\n{nongating} non-gating failure(s) in non-deploy specs — reported but not blocking.")
        print("Run with WHEELS_CLI_TEST_STRICT=1 to gate on them too.")
    return 1 if gating else 0


if __name__ == "__main__":
    sys.exit(main())
