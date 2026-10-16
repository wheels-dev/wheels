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
    with open(os.path.join(HERE, "run-suite.sh"), encoding="utf-8") as fh:
        text = fh.read()
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
    # Totals agree with the tree unless a test overrides them on purpose: the
    # shared walker reconciles pass/fail/error counts against the specs it finds.
    passed = 1 + (0 if nested_failure else 1)
    if fail is None:
        fail = 1 + (1 if nested_failure else 0)
    return {"totalSpecs": passed + fail + error, "totalPass": passed, "totalFail": fail,
            "totalError": error, "totalSkipped": 0, "bundleStats": bundles}


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

    def test_runner_error_envelope_is_an_evaluation_error(self):
        # Parseable JSON that is not a TestBox result must never read as a verdict.
        code, out, verdict = self.run_parser(None, raw=json.dumps({"success": False, "error": "boot failed"}))
        self.assertEqual(code, 1, out)
        self.assertIsNone(verdict)
        self.assertIn("not a usable TestBox result", out)

    def test_unparseable_response_is_an_evaluation_error(self):
        code, out, verdict = self.run_parser(None, raw="<html>500</html>")
        self.assertEqual(code, 1, out)
        self.assertIsNone(verdict)


CI_ENV = {"GITHUB_SERVER_URL": "https://github.com", "GITHUB_REPOSITORY": "wheels-dev/wheels",
          "GITHUB_RUN_ID": "38287218547", "GITHUB_SHA": "9fcc17c5d0123456789abcdef0123456789abcd"}
LEGACY_NOTE = ("Linux baseline from this PR run: https://github.com/wheels-dev/wheels/actions/runs/1/job/2"
               " (1bd2eef95, v0.693.0): 5850 pass / 0 fail / 0 error / 29 skipped."
               " totalSpecs is the sum of those reported categories.")
ISSUE_NOTE = "RustCFML#431 (an included template lost its exception type) is fixed in v0.693.0."


class WriteBaselineTest(unittest.TestCase):
    """--write-baseline rewrites the provenance note in _notes, so a regenerated
    baseline (e.g. an auto-bump PR) never carries the previous run's numbers."""

    def write(self, notes=None, env=None):
        with tempfile.TemporaryDirectory() as tmp:
            out = os.path.join(tmp, "out.json")
            base = os.path.join(tmp, "baseline.json")
            with open(out, "w") as fh:
                json.dump(_result(nested_failure=False), fh)
            existing = dict(BASELINE)
            if notes is not None:
                existing["_notes"] = notes
            with open(base, "w") as fh:
                json.dump(existing, fh)
            run_env = {k: v for k, v in os.environ.items() if not k.startswith("GITHUB_")}
            run_env.update(env or {})
            proc = subprocess.run(
                [sys.executable, "-", out, base, "write", "v0.732.0", REPO_ROOT],
                input=_parser_source(), capture_output=True, text=True, env=run_env)
            self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
            with open(base) as fh:
                return json.load(fh)["_notes"]

    def test_ci_run_note_names_the_run_commit_version_and_totals(self):
        note = self.write(notes=[ISSUE_NOTE], env=CI_ENV)[0]
        self.assertIn("https://github.com/wheels-dev/wheels/actions/runs/38287218547", note)
        self.assertIn("9fcc17c5d", note)
        self.assertNotIn("9fcc17c5d0", note)
        self.assertIn("v0.732.0", note)
        self.assertIn("2 pass / 1 fail / 0 error / 0 skipped", note)

    def test_previous_provenance_note_is_replaced_not_kept(self):
        notes = self.write(notes=[LEGACY_NOTE, ISSUE_NOTE], env=CI_ENV)
        self.assertEqual(len(notes), 2, notes)
        self.assertNotIn("5850 pass", " ".join(notes))
        self.assertEqual(notes[1], ISSUE_NOTE)

    def test_hand_written_note_from_a_bump_pr_is_replaced(self):
        # The wording a person used on #4577 when fixing the note by hand.
        by_hand = ("Linux baseline from the version-check run that opened this bump: "
                   "https://github.com/wheels-dev/wheels/actions/runs/38287218547/job/114938368850"
                   " (9fcc17c5d, v0.732.0): 7273 pass / 0 fail / 0 error / 177 skipped.")
        notes = self.write(notes=[by_hand, ISSUE_NOTE], env=CI_ENV)
        self.assertEqual(len(notes), 2, notes)
        self.assertNotIn("7273 pass", " ".join(notes))

    def test_rewriting_twice_keeps_one_provenance_note(self):
        first = self.write(notes=[LEGACY_NOTE, ISSUE_NOTE], env=CI_ENV)
        again = self.write(notes=first, env=dict(CI_ENV, GITHUB_RUN_ID="99"))
        self.assertEqual(len(again), 2, again)
        self.assertIn("/actions/runs/99", again[0])
        self.assertEqual(again[1], ISSUE_NOTE)

    def test_human_notes_keep_their_order(self):
        other = "SystemUtilSpec: a null Java-version placeholder is not an engine defect."
        notes = self.write(notes=[ISSUE_NOTE, LEGACY_NOTE, other], env=CI_ENV)
        self.assertEqual(notes[1:], [ISSUE_NOTE, other])

    def test_local_run_says_so_and_links_no_run(self):
        note = self.write(notes=[ISSUE_NOTE])[0]
        self.assertIn("a local run", note)
        self.assertNotIn("actions/runs", note)
        self.assertIn("v0.732.0", note)

    def test_baseline_without_notes_gets_the_provenance_note(self):
        notes = self.write(notes=None, env=CI_ENV)
        self.assertEqual(len(notes), 1)
        self.assertIn("/actions/runs/38287218547", notes[0])


if __name__ == "__main__":
    unittest.main(verbosity=2)
