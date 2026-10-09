#!/usr/bin/env python3
"""Tests for check-version.sh: which release it evaluates (the newest, prereleases
included, with a fallback to a newer stable), its KNOWN_BAD skip, and the KNOWN_BAD
file itself.

Runs the real script against a scratch copy of the pin, with a fake `gh` on PATH
standing in for the release API and a stub run-suite.sh that only records that it
ran, so it needs no network and no engine:

    python3 tools/rustcfml/test_check_version.py
"""

import os
import re
import shutil
import stat
import subprocess
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))

# Stands in for the release API. `releases/latest` (GitHub's latest *stable* release)
# answers FAKE_STABLE; the release list answers FAKE_RELEASES (one tag per line,
# prereleases included, drafts already excluded by the --jq filter).
FAKE_GH = """#!/usr/bin/env bash
case "$*" in
  *releases/latest*) echo "$FAKE_STABLE" ;;
  *releases*) printf '%s\\n' $FAKE_RELEASES ;;
  *) echo "unexpected gh call: $*" >&2; exit 1 ;;
esac
"""

# Stands in for the suite: records the version it was asked to run and answers with
# the exit code SUITE_RC lists for it ("v0.724.1=3 v0.721.0=0"; default 1, "could not
# evaluate"). A rejection (3) writes a verdict with a fingerprint, as run-suite.sh does.
# --write-baseline (after a bump) is recorded and succeeds.
STUB_SUITE = """#!/usr/bin/env bash
if [ "${1:-}" = "--write-baseline" ]; then echo "baseline $RUSTCFML_VERSION" >> "$SUITE_LOG"; exit 0; fi
echo "$RUSTCFML_VERSION" >> "$SUITE_LOG"
rc=1
for pair in $SUITE_RC; do [ "${pair%%=*}" = "$RUSTCFML_VERSION" ] && rc="${pair#*=}"; done
if [ "$rc" = 3 ]; then printf '{"fingerprint": "fp-%s"}' "$RUSTCFML_VERSION" > "$RUSTCFML_RESULT_JSON"; fi
exit "$rc"
"""

# Stands in for bump-pin.sh: records the tag it was asked to pin.
STUB_BUMP = """#!/usr/bin/env bash
echo "$1" >> "$BUMP_LOG"
"""


def _entries(text):
    return [line for line in text.splitlines() if line.strip() and not line.lstrip().startswith("#")]


class CheckVersionTest(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.tools = os.path.join(self.tmp, "tools", "rustcfml")
        os.makedirs(self.tools)
        shutil.copy(os.path.join(HERE, "check-version.sh"), self.tools)
        with open(os.path.join(self.tools, "ENGINE_VERSION"), "w") as fh:
            fh.write("v0.700.0\n")
        with open(os.path.join(self.tools, "KNOWN_BAD"), "w") as fh:
            fh.write("# comment line\n"
                     "v0.712.0 https://example.test/issue/1 Hangs the suite.\n")
        self._executable(os.path.join(self.tools, "run-suite.sh"), STUB_SUITE)
        self._executable(os.path.join(self.tools, "bump-pin.sh"), STUB_BUMP)
        self.bin = os.path.join(self.tmp, "bin")
        os.makedirs(self.bin)
        self._executable(os.path.join(self.bin, "gh"), FAKE_GH)
        self.suite_log = os.path.join(self.tmp, "suite.log")
        self.bump_log = os.path.join(self.tmp, "bump.log")
        self.github_env = os.path.join(self.tmp, "github.env")

    def tearDown(self):
        shutil.rmtree(self.tmp)

    @staticmethod
    def _executable(path, body):
        with open(path, "w") as fh:
            fh.write(body)
        os.chmod(path, os.stat(path).st_mode | stat.S_IEXEC)

    def check(self, latest, stable=None, releases=None, suite_rc="", github_env=False):
        """latest: the newest release (prerelease or not); stable: GitHub's latest
        stable release (default: the same tag); releases: every tag the list returns."""
        env = dict(os.environ, PATH=self.bin + os.pathsep + os.environ["PATH"],
                   FAKE_STABLE=stable or latest,
                   FAKE_RELEASES=" ".join(releases or [latest, stable or latest]),
                   SUITE_LOG=self.suite_log, BUMP_LOG=self.bump_log, SUITE_RC=suite_rc,
                   RUNNER_TEMP=self.tmp)
        env.pop("GITHUB_ENV", None)
        if github_env:
            env["GITHUB_ENV"] = self.github_env
        proc = subprocess.run(["bash", os.path.join(self.tools, "check-version.sh")],
                              capture_output=True, text=True, env=env)
        return proc.returncode, proc.stdout + proc.stderr

    def suite_ran(self):
        return os.path.exists(self.suite_log)

    def suite_runs(self):
        if not os.path.exists(self.suite_log):
            return []
        with open(self.suite_log) as fh:
            return fh.read().split("\n")[:-1]

    def bumped_to(self):
        if not os.path.exists(self.bump_log):
            return []
        with open(self.bump_log) as fh:
            return fh.read().split()

    def exported(self):
        with open(self.github_env) as fh:
            return dict(line.split("=", 1) for line in fh.read().splitlines())

    # --- which release is evaluated (pin policy, orch1 2026-10-09) ---

    def test_a_newer_prerelease_is_evaluated_not_just_the_latest_stable(self):
        # v0.724.1 is a prerelease; GitHub's "latest" (stable) is still v0.721.0.
        self.check("v0.724.1", stable="v0.721.0", releases=["v0.724.1", "v0.724.0", "v0.721.0"])
        self.assertEqual(self.suite_runs()[:1], ["v0.724.1"])

    def test_newest_is_chosen_by_version_not_by_listing_order(self):
        self.check("v0.724.1", stable="v0.721.0", releases=["v0.721.0", "v0.724.1", "v0.99.0", "v0.723.0"])
        self.assertEqual(self.suite_runs()[:1], ["v0.724.1"])

    def test_non_version_tags_are_ignored(self):
        self.check("v0.724.1", stable="v0.721.0", releases=["snapshot", "v0.724.1", "nightly-1"])
        self.assertEqual(self.suite_runs()[:1], ["v0.724.1"])

    def test_green_newest_is_pinned(self):
        code, out = self.check("v0.724.1", stable="v0.721.0", suite_rc="v0.724.1=0", github_env=True)
        self.assertEqual(code, 0, out)
        self.assertEqual(self.bumped_to(), ["v0.724.1"])
        self.assertEqual(self.exported()["RUSTCFML_LATEST"], "v0.724.1")

    def test_rejected_newest_falls_back_to_a_newer_green_stable(self):
        code, out = self.check("v0.724.1", stable="v0.721.0", suite_rc="v0.724.1=3 v0.721.0=0", github_env=True)
        self.assertEqual(code, 0, out)
        self.assertEqual(self.suite_runs()[:2], ["v0.724.1", "v0.721.0"])
        self.assertEqual(self.bumped_to(), ["v0.721.0"])
        env = self.exported()
        self.assertEqual(env["RUSTCFML_LATEST"], "v0.721.0")
        # The newest's rejection is still reported (its own issue).
        self.assertEqual(env["RUSTCFML_REJECTED"], "v0.724.1")
        self.assertEqual(env["RUSTCFML_FINGERPRINT"], "fp-v0.724.1")

    def test_both_rejected_pins_nothing_and_reports_the_newest(self):
        code, out = self.check("v0.724.1", stable="v0.721.0", suite_rc="v0.724.1=3 v0.721.0=3", github_env=True)
        self.assertEqual(code, 0, out)
        self.assertEqual(self.bumped_to(), [])
        env = self.exported()
        self.assertNotIn("RUSTCFML_LATEST", env)
        self.assertEqual(env["RUSTCFML_REJECTED"], "v0.724.1")

    def test_no_fallback_when_the_stable_is_not_newer_than_the_pin(self):
        self.check("v0.724.1", stable="v0.700.0", suite_rc="v0.724.1=3")
        self.assertEqual(self.suite_runs(), ["v0.724.1"])

    def test_no_fallback_when_the_newest_could_not_be_evaluated(self):
        code, out = self.check("v0.724.1", stable="v0.721.0", suite_rc="v0.724.1=1 v0.721.0=0")
        self.assertEqual(code, 1, out)
        self.assertEqual(self.suite_runs(), ["v0.724.1"])
        self.assertEqual(self.bumped_to(), [])

    def test_known_bad_newest_falls_back_to_the_stable(self):
        code, out = self.check("v0.712.0", stable="v0.711.0", releases=["v0.712.0", "v0.711.0"], suite_rc="v0.711.0=0")
        self.assertEqual(code, 0, out)
        self.assertIn("::notice::", out)
        self.assertEqual(self.suite_runs()[:1], ["v0.711.0"])
        self.assertEqual(self.bumped_to(), ["v0.711.0"])

    def test_listed_release_is_skipped_with_its_reason(self):
        code, out = self.check("v0.712.0")
        self.assertEqual(code, 0, out)
        self.assertFalse(self.suite_ran(), "the suite ran against a KNOWN_BAD release")
        self.assertIn("::notice::", out)
        self.assertIn("v0.712.0", out)
        self.assertIn("https://example.test/issue/1", out)
        self.assertIn("Hangs the suite.", out)
        with open(os.path.join(self.tools, "ENGINE_VERSION")) as fh:
            self.assertEqual(fh.read(), "v0.700.0\n")

    def test_unlisted_release_is_still_evaluated(self):
        code, out = self.check("v0.713.0")
        self.assertTrue(self.suite_ran(), out)
        with open(self.suite_log) as fh:
            self.assertEqual(fh.read(), "v0.713.0\n")
        self.assertNotIn("KNOWN_BAD", out)

    def test_a_tag_sharing_a_prefix_with_a_listed_one_is_not_skipped(self):
        # "v0.712" is a prefix of both; only an exact KNOWN_BAD match skips. (The tag must
        # be newer than the pin v0.700.0 to be evaluated at all.)
        self.check("v0.7120.0")
        self.assertTrue(self.suite_ran())

    def test_a_release_older_than_the_pin_is_not_evaluated(self):
        code, out = self.check("v0.71.0")
        self.assertEqual(code, 0, out)
        self.assertFalse(self.suite_ran())

    def test_missing_known_bad_file_changes_nothing(self):
        os.remove(os.path.join(self.tools, "KNOWN_BAD"))
        self.check("v0.712.0")
        self.assertTrue(self.suite_ran(), "without KNOWN_BAD every newer release is evaluated")

    def test_pinned_release_runs_nothing(self):
        code, out = self.check("v0.700.0")
        self.assertEqual(code, 0, out)
        self.assertFalse(self.suite_ran())

    def test_every_real_entry_has_tag_link_and_reason(self):
        with open(os.path.join(HERE, "KNOWN_BAD")) as fh:
            entries = _entries(fh.read())
        self.assertTrue(entries, "KNOWN_BAD lists no release")
        for line in entries:
            parts = line.split(None, 2)
            self.assertEqual(len(parts), 3, "need <tag> <link> <reason>: %r" % line)
            tag, link, reason = parts
            self.assertRegex(tag, r"^v[0-9]+\.[0-9]+\.[0-9]+$", line)
            self.assertTrue(re.match(r"^https://github\.com/RustCFML/RustCFML/(issues|commit|pull)/", link), line)
            self.assertGreater(len(reason.strip()), 20, line)


if __name__ == "__main__":
    unittest.main()
