#!/usr/bin/env python3
"""Tests for run-suite.sh's result parsing, comparison and exit codes (#3687).

Runs the Python block embedded in tools/rustcfml/run-suite.sh — the exact code
CI executes — against small TestBox results, so it needs no engine:

    python3 tools/rustcfml/test_run_suite.py
"""

import json
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(os.path.dirname(HERE))

KNOWN = "b.Known :: Top :: known failure"
NESTED = "b.Nested :: Outer > Inner :: nested failure"


def _parser_source():
    text = open(os.path.join(HERE, "run-suite.sh"), encoding="utf-8").read()
    start = text.index("<<'PY'\n") + len("<<'PY'\n")
    return text[start:text.index("\nPY\n", start)] + "\n"


def _spec(name, status="Passed", message=""):
    return {"name": name, "status": status, "failMessage": message, "failDetail": ""}


def _result(nested_failure=True, bundle_exception=False, fail=None, error=0):
    bundles = [
        {"name": "b.Known", "suiteStats": [
            {"name": "Top", "specStats": [_spec("known failure", "Failed", "old")]}]},
        # A failure two suites deep, under suiteStats — what the old walker missed.
        {"name": "b.Nested", "suiteStats": [
            {"name": "Outer", "specStats": [_spec("ok")], "suiteStats": [
                {"name": "Inner", "specStats": [
                    _spec("nested failure", "Failed", "Expected 404 but received 500")
                    if nested_failure else _spec("nested failure")]}]}]},
    ]
    if bundle_exception:
        bundles.append({"name": "b.Broken", "globalException": {"Message": "boom"}, "suiteStats": []})
    if fail is None:
        fail = 1 + (1 if nested_failure else 0)
    return {"totalSpecs": 4, "totalPass": 2, "totalFail": fail, "totalError": error,
            "totalSkipped": 0, "bundleStats": bundles}


BASELINE = {"engineVersion": "v0.637.0",
            "totals": {"totalSpecs": 4, "totalPass": 2, "totalFail": 1, "totalError": 0, "totalSkipped": 0},
            "failing": [KNOWN]}


class RunSuiteParserTest(unittest.TestCase):

    def run_parser(self, result, raw=None):
        with tempfile.TemporaryDirectory() as tmp:
            out = os.path.join(tmp, "out.json")
            base = os.path.join(tmp, "baseline.json")
            verdict = os.path.join(tmp, "verdict.json")
            with open(out, "w") as fh:
                fh.write(raw if raw is not None else json.dumps(result))
            with open(base, "w") as fh:
                json.dump(BASELINE, fh)
            env = dict(os.environ, RUSTCFML_RESULT_JSON=verdict)
            env.pop("GITHUB_STEP_SUMMARY", None)
            proc = subprocess.run(
                [sys.executable, "-", out, base, "compare", "v9.9.9", REPO_ROOT],
                input=_parser_source(), capture_output=True, text=True, env=env)
            data = None
            if os.path.exists(verdict):
                with open(verdict) as fh:
                    data = json.load(fh)
            return proc.returncode, proc.stdout, data

    def test_nested_failure_is_named_and_rejects(self):
        code, out, verdict = self.run_parser(_result())
        self.assertEqual(code, 3, out)
        self.assertEqual(verdict["verdict"], "rejected")
        self.assertEqual([n["key"] for n in verdict["new"]], [NESTED])
        self.assertIn("Expected 404 but received 500", verdict["new"][0]["message"])
        self.assertEqual(verdict["walkMismatch"], [])
        self.assertIn("(2 distinct failing entries)", out)

    def test_only_known_failures_accepts(self):
        code, out, verdict = self.run_parser(_result(nested_failure=False))
        self.assertEqual(code, 0, out)
        self.assertEqual(verdict["verdict"], "accepted")
        self.assertEqual(verdict["new"], [])

    def test_bundle_exception_key_and_rejects(self):
        code, out, verdict = self.run_parser(_result(nested_failure=False, bundle_exception=True, error=1))
        self.assertEqual(code, 3, out)
        self.assertEqual([n["key"] for n in verdict["new"]], ["b.Broken :: (bundle-level exception)"])

    def test_totals_above_baseline_without_named_entry_rejects(self):
        code, out, verdict = self.run_parser(_result(nested_failure=False, fail=5))
        self.assertEqual(code, 3, out)
        self.assertEqual(verdict["totalsWorse"], ["totalFail: 1 -> 5"])
        self.assertTrue(verdict["walkMismatch"], "a count the walk cannot see must be reported")

    def test_fingerprint_is_stable_and_tracks_the_failure_set(self):
        _, _, first = self.run_parser(_result())
        _, _, again = self.run_parser(_result())
        _, _, other = self.run_parser(_result(nested_failure=False, bundle_exception=True, error=1))
        self.assertEqual(first["fingerprint"], again["fingerprint"])
        self.assertNotEqual(first["fingerprint"], other["fingerprint"])

    def test_fingerprint_ignores_counts(self):
        # Same named failures, a different (flaky) fail total: no re-notify.
        _, _, base = self.run_parser(_result())
        _, _, noisy = self.run_parser(_result(fail=7))
        self.assertEqual(base["new"], noisy["new"])
        self.assertNotEqual(base["totals"], noisy["totals"])
        self.assertEqual(base["fingerprint"], noisy["fingerprint"])

    def test_unparseable_response_is_an_evaluation_error(self):
        code, out, verdict = self.run_parser(None, raw="<html>500</html>")
        self.assertEqual(code, 1, out)
        self.assertIsNone(verdict)


if __name__ == "__main__":
    unittest.main(verbosity=2)
