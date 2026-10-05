#!/usr/bin/env python3
"""Tests for check-version.sh's KNOWN_BAD skip, and for the KNOWN_BAD file itself.

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

FAKE_GH = """#!/usr/bin/env bash
echo "$FAKE_LATEST"
"""

# Stands in for the suite: records the version it was asked to run, then reports
# "could not evaluate" (exit 1), so check-version.sh stops without bumping anything.
STUB_SUITE = """#!/usr/bin/env bash
echo "$RUSTCFML_VERSION" >> "$SUITE_LOG"
exit 1
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
        self.bin = os.path.join(self.tmp, "bin")
        os.makedirs(self.bin)
        self._executable(os.path.join(self.bin, "gh"), FAKE_GH)
        self.suite_log = os.path.join(self.tmp, "suite.log")

    def tearDown(self):
        shutil.rmtree(self.tmp)

    @staticmethod
    def _executable(path, body):
        with open(path, "w") as fh:
            fh.write(body)
        os.chmod(path, os.stat(path).st_mode | stat.S_IEXEC)

    def check(self, latest):
        env = dict(os.environ, PATH=self.bin + os.pathsep + os.environ["PATH"],
                   FAKE_LATEST=latest, SUITE_LOG=self.suite_log)
        env.pop("GITHUB_ENV", None)
        proc = subprocess.run(["bash", os.path.join(self.tools, "check-version.sh")],
                              capture_output=True, text=True, env=env)
        return proc.returncode, proc.stdout + proc.stderr

    def suite_ran(self):
        return os.path.exists(self.suite_log)

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

    def test_a_tag_that_only_prefixes_a_listed_one_is_not_skipped(self):
        self.check("v0.71.0")
        self.assertTrue(self.suite_ran())

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
