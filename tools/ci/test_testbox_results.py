"""Tests for tools/ci/testbox_results.py (#3694). Run: python3 tools/ci/test_testbox_results.py"""
import contextlib
import importlib.util
import io
import os
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
FIXTURES = os.path.join(HERE, "fixtures", "testbox")
_spec = importlib.util.spec_from_file_location("testbox_results", os.path.join(HERE, "testbox_results.py"))
tb = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(tb)


def run(name, *flags):
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        code = tb.main([os.path.join(FIXTURES, name), *flags])
    return code, out.getvalue()


class WalkTests(unittest.TestCase):

    def load(self, name):
        import json
        with open(os.path.join(FIXTURES, name)) as fh:
            return json.load(fh)

    def test_finds_a_failure_nested_two_suites_deep(self):
        found = tb.walk(self.load("nested-deploy-failure.json"))
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0]["path"], ["outer", "inner"])
        self.assertEqual(found[0]["name"], "sentinel")

    def test_counts_a_bundle_exception_as_an_error(self):
        found = tb.walk(self.load("bundle-exception-deploy.json"))
        self.assertEqual([f["kind"] for f in found], ["BundleError"])
        self.assertIn("sentinel beforeAll failure", found[0]["message"])

    def test_reads_legacy_nestedSuiteStats(self):
        found = tb.walk(self.load("legacy-nested.json"))
        self.assertEqual([f["name"] for f in found], ["legacy"])

    def test_reconciles_when_the_tree_matches_the_totals(self):
        r = self.load("nested-nondeploy-failure.json")
        self.assertEqual(tb.reconcile(r, tb.walk(r)), [])


class ExitCodeTests(unittest.TestCase):
    """The #3694 cases: each of these exited 0 under the old parser."""

    def test_strict_fails_on_a_nested_deploy_failure(self):
        code, out = run("nested-deploy-failure.json", "--strict")
        self.assertEqual(code, 1)
        self.assertIn("sentinel", out)

    def test_nested_deploy_failure_gates_even_without_strict(self):
        self.assertEqual(run("nested-deploy-failure.json")[0], 1)

    def test_strict_fails_on_a_bundle_exception(self):
        code, out = run("bundle-exception-deploy.json", "--strict")
        self.assertEqual(code, 1)
        self.assertIn("sentinel beforeAll failure", out)

    def test_nested_nondeploy_failure_is_reported_but_non_gating_by_default(self):
        code, out = run("nested-nondeploy-failure.json")
        self.assertEqual(code, 0)
        self.assertIn("[non-gating]", out)
        self.assertIn("deep", out)

    def test_nested_nondeploy_failure_gates_in_strict(self):
        self.assertEqual(run("nested-nondeploy-failure.json", "--strict")[0], 1)

    def test_counts_that_do_not_reconcile_fail_closed_even_without_strict(self):
        code, out = run("unreconciled.json")
        self.assertEqual(code, 3)
        self.assertIn("COUNTS DON'T RECONCILE", out)

    def test_unknown_status_gates(self):
        self.assertEqual(run("unknown-status.json")[0], 1)

    def test_clean_result_passes(self):
        self.assertEqual(run("clean.json", "--strict")[0], 0)

    def test_unreadable_result_is_exit_2(self):
        self.assertEqual(run("does-not-exist.json")[0], 2)


class EnvelopeValidationTests(unittest.TestCase):
    """rev1-r2 MUST-FIX on #3695: anything that is not a real TestBox result
    must FAIL, never read as zero failures."""

    def assert_rejected(self, name):
        code, out = run(name, "--strict")
        self.assertEqual(code, 2, f"{name} should be rejected, got exit {code}: {out}")
        self.assertIn("NOT A TESTBOX RESULT", out)
        return out

    def test_rejects_a_json_array(self):
        self.assert_rejected("not-an-object.json")

    def test_rejects_an_empty_object(self):
        self.assert_rejected("empty-object.json")

    def test_rejects_a_runner_error_envelope(self):
        out = self.assert_rejected("error-envelope.json")
        self.assertIn("runner failed", out)

    def test_rejects_totals_without_a_bundle_tree(self):
        self.assert_rejected("totals-only.json")

    def test_rejects_a_negative_total(self):
        self.assert_rejected("negative-total.json")

    def test_accepts_whole_number_float_totals_from_adobe(self):
        # Adobe CF serialises totals as floats (5792.0); that is still valid.
        code, out = run("adobe-float-totals.json", "--strict")
        self.assertEqual(code, 1)  # the one real failure gates
        self.assertNotIn("NOT A TESTBOX RESULT", out)

    def test_rejects_an_empty_bundle_object(self):
        # rev1-r2 follow-up: {} as a bundle has no tree to walk.
        self.assert_rejected("bundle-empty-object.json")

    def test_rejects_a_null_bundle(self):
        self.assert_rejected("bundle-null.json")

    def test_passes_claimed_without_passed_leaves_do_not_reconcile(self):
        code, out = run("pass-mismatch.json", "--strict")
        self.assertEqual(code, 3)
        self.assertIn("totalPass is 5 but 1", out)

    def test_rejects_an_empty_run(self):
        # No bundles, nothing executed: a vacuous run cannot certify a pass.
        self.assert_rejected("empty-valid.json")


if __name__ == "__main__":
    unittest.main()
