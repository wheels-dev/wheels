"""Tests for tools/ci/release_republish_guard.py. Run: python3 tools/ci/test_release_republish_guard.py

Each case runs the guard end to end against a fake `gh` (GH_BIN) that answers
the two lookups with canned responses shaped like the real `gh api` output: on
a non-2xx reply gh prints the JSON body on stdout, "gh: <message> (HTTP nnn)"
on stderr, and exits 1.
"""
import contextlib
import importlib.util
import io
import json
import os
import stat
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("release_republish_guard", os.path.join(HERE, "release_republish_guard.py"))
guard = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(guard)

REPO = "wheels-dev/wheels"
TAG = "v4.2.0"
SHA = "a" * 40
OTHER_SHA = "b" * 40

FAKE_GH = """#!/usr/bin/env python3
import json, os, sys
responses = json.load(open(os.environ["FAKE_GH_RESPONSES"]))
path = sys.argv[2]
kind = "release" if "/releases/tags/" in path else "commit"
r = responses[kind]
sys.stdout.write(r.get("stdout", ""))
sys.stderr.write(r.get("stderr", ""))
sys.exit(r.get("rc", 0))
"""


def ok(value):
    return {"stdout": value + "\n", "rc": 0}


def not_found():
    return {"stdout": '{"message":"Not Found","status":"404"}', "stderr": "gh: Not Found (HTTP 404)\n", "rc": 1}


def no_commit():
    return {"stdout": '{"message":"No commit found for SHA: v4.2.0","status":"422"}',
            "stderr": "gh: No commit found for SHA: v4.2.0 (HTTP 422)\n", "rc": 1}


def server_error():
    return {"stdout": '{"message":"Server Error","status":"502"}', "stderr": "gh: Server Error (HTTP 502)\n", "rc": 1}


def network_error():
    return {"stderr": "Post \"https://api.github.com/graphql\": net/http: TLS handshake timeout\n", "rc": 1}


class GuardTests(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        fake = os.path.join(self.tmp.name, "gh")
        with open(fake, "w") as fh:
            fh.write(FAKE_GH)
        os.chmod(fake, os.stat(fake).st_mode | stat.S_IEXEC)
        self.responses = os.path.join(self.tmp.name, "responses.json")
        self.env = {"GH_BIN": fake, "FAKE_GH_RESPONSES": self.responses}
        self.saved = {k: os.environ.get(k) for k in self.env}
        os.environ.update(self.env)

    def tearDown(self):
        for key, value in self.saved.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value
        self.tmp.cleanup()

    def run_guard(self, release, commit):
        with open(self.responses, "w") as fh:
            json.dump({"release": release, "commit": commit}, fh)
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = guard.main(["--repo", REPO, "--tag", TAG, "--sha", SHA])
        return code, out.getvalue()

    def test_refuses_a_release_that_has_assets(self):
        code, out = self.run_guard(ok("20"), ok(SHA))
        self.assertEqual(code, 1)
        self.assertIn("already published with 20 assets", out)
        self.assertIn("bump the version in wheels.json", out)

    def test_refuses_a_release_with_one_asset_from_a_partial_upload(self):
        code, out = self.run_guard(ok("1"), ok(SHA))
        self.assertEqual(code, 1)
        self.assertIn("delete that release by hand first", out)

    def test_refuses_a_tag_at_another_commit(self):
        code, out = self.run_guard(not_found(), ok(OTHER_SHA))
        self.assertEqual(code, 1)
        self.assertIn("already points at %s" % OTHER_SHA, out)

    def test_refuses_an_empty_release_whose_tag_is_at_another_commit(self):
        code, out = self.run_guard(ok("0"), ok(OTHER_SHA))
        self.assertEqual(code, 1)
        self.assertIn("not this commit", out)

    def test_allows_an_empty_release_on_this_commit(self):
        code, out = self.run_guard(ok("0"), ok(SHA))
        self.assertEqual(code, 0, out)
        self.assertIn("exists with no assets", out)
        self.assertIn("points at this commit", out)

    def test_allows_a_new_version(self):
        code, out = self.run_guard(not_found(), no_commit())
        self.assertEqual(code, 0, out)
        self.assertIn("No release for v4.2.0 yet", out)
        self.assertIn("No tag v4.2.0 yet", out)

    def test_allows_a_tag_404(self):
        code, out = self.run_guard(not_found(), not_found())
        self.assertEqual(code, 0, out)

    def test_fails_closed_on_a_release_lookup_api_error(self):
        code, out = self.run_guard(server_error(), no_commit())
        self.assertEqual(code, 1)
        self.assertIn("Could not check for an existing v4.2.0 release", out)
        self.assertIn("HTTP 502", out)

    def test_fails_closed_on_a_network_error(self):
        code, out = self.run_guard(network_error(), no_commit())
        self.assertEqual(code, 1)
        self.assertIn("refusing to publish", out)

    def test_fails_closed_on_a_tag_lookup_api_error(self):
        code, out = self.run_guard(not_found(), server_error())
        self.assertEqual(code, 1)
        self.assertIn("Could not check tag v4.2.0", out)

    def test_fails_closed_on_an_unparseable_asset_count(self):
        code, out = self.run_guard(ok("null"), no_commit())
        self.assertEqual(code, 1)
        self.assertIn("Unexpected asset count", out)

    def test_fails_closed_when_gh_is_missing(self):
        os.environ["GH_BIN"] = os.path.join(self.tmp.name, "no-such-gh")
        code, out = self.run_guard(not_found(), no_commit())
        self.assertEqual(code, 1)
        self.assertIn("refusing to publish", out)


if __name__ == "__main__":
    unittest.main(verbosity=2)
