#!/usr/bin/env python3
"""Tests for bump-pin.sh, which moves the RustCFML engine pin (#3812).

Runs the real script against a scratch copy of the pinned files, with a fake
`gh` on PATH standing in for the release API, so it needs no network:

    python3 tools/rustcfml/test_bump_pin.py
"""

import os
import shutil
import stat
import subprocess
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(os.path.dirname(HERE))
CFC_REL = os.path.join("cli", "lucli", "services", "rustcfml", "RustCFMLEngine.cfc")

ASSETS = ["rustcfml-linux-aarch64", "rustcfml-linux-x86_64", "rustcfml-macos-aarch64"]
NEW = {a: format(i + 1, "x") * 64 for i, a in enumerate(ASSETS)}

FAKE_GH = """#!/usr/bin/env bash
echo "$*" >> "$FAKE_GH_LOG"
[ "${FAKE_GH_EXIT:-0}" = "0" ] || exit "$FAKE_GH_EXIT"
cat "$FAKE_GH_OUTPUT"
"""


def _digests(skip=(), override=None):
    lines = ["LICENSE sha256:" + "0" * 64]
    for asset in ASSETS:
        if asset in skip:
            continue
        lines.append("%s %s" % (asset, (override or {}).get(asset, "sha256:" + NEW[asset])))
    lines.append("rustcfml-windows-x86_64.exe sha256:" + "e" * 64)
    return "\n".join(lines) + "\n"


class BumpPinTest(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.tools = os.path.join(self.tmp, "tools", "rustcfml")
        os.makedirs(self.tools)
        for name in ("bump-pin.sh", "engine-sha256.sh", "ENGINE_VERSION", "ENGINE_SHA256"):
            shutil.copy(os.path.join(HERE, name), self.tools)
        self.cfc = os.path.join(self.tmp, CFC_REL)
        os.makedirs(os.path.dirname(self.cfc))
        shutil.copy(os.path.join(REPO_ROOT, CFC_REL), self.cfc)
        self.bin = os.path.join(self.tmp, "bin")
        os.makedirs(self.bin)
        gh = os.path.join(self.bin, "gh")
        with open(gh, "w") as fh:
            fh.write(FAKE_GH)
        os.chmod(gh, os.stat(gh).st_mode | stat.S_IEXEC)
        self.gh_log = os.path.join(self.tmp, "gh.log")

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def snapshot(self):
        out = {}
        for path in (os.path.join(self.tools, "ENGINE_VERSION"),
                     os.path.join(self.tools, "ENGINE_SHA256"), self.cfc):
            with open(path, "rb") as fh:
                out[path] = fh.read()
        return out

    def bump(self, digests, tag="v9.9.9", gh_exit=0):
        out = os.path.join(self.tmp, "digests.txt")
        with open(out, "w") as fh:
            fh.write(digests)
        env = dict(os.environ, PATH=self.bin + os.pathsep + os.environ["PATH"],
                   FAKE_GH_OUTPUT=out, FAKE_GH_LOG=self.gh_log, FAKE_GH_EXIT=str(gh_exit))
        proc = subprocess.run(["bash", os.path.join(self.tools, "bump-pin.sh"), tag],
                              capture_output=True, text=True, env=env)
        return proc.returncode, proc.stdout + proc.stderr

    def assert_refused(self, digests, **kw):
        before = self.snapshot()
        code, out = self.bump(digests, **kw)
        self.assertEqual(code, 1, out)
        self.assertEqual(before, self.snapshot(), "a pin moved although the bump was refused")
        return out

    def test_moves_version_and_every_sha256_pin(self):
        with open(self.cfc) as fh:
            cfc_before = fh.read()
        code, out = self.bump(_digests())
        self.assertEqual(code, 0, out)
        with open(self.gh_log) as fh:
            self.assertIn("releases/tags/v9.9.9", fh.read())
        with open(os.path.join(self.tools, "ENGINE_VERSION")) as fh:
            self.assertEqual(fh.read(), "v9.9.9\n")
        with open(os.path.join(self.tools, "ENGINE_SHA256")) as fh:
            self.assertEqual(fh.read(), "".join("%s  %s\n" % (NEW[a], a) for a in ASSETS))
        with open(self.cfc) as fh:
            cfc = fh.read()
        self.assertIn('\tvariables.engineVersion = "v9.9.9";\n', cfc)
        for asset in ASSETS:
            self.assertIn('\tvariables.engineSha256["%s"] = "%s";\n' % (asset, NEW[asset]), cfc)
        # Only the pin lines changed.
        changed = [(a, b) for a, b in zip(cfc_before.splitlines(), cfc.splitlines()) if a != b]
        self.assertEqual(len(changed), 1 + len(ASSETS), changed)
        self.assertEqual(len(cfc_before.splitlines()), len(cfc.splitlines()))
        self.assertFalse(os.path.exists(self.cfc + ".bak"))

    def test_missing_digest_leaves_every_pin(self):
        out = self.assert_refused(_digests(skip={"rustcfml-macos-aarch64"}))
        self.assertIn("rustcfml-macos-aarch64", out)

    def test_non_sha256_digest_leaves_every_pin(self):
        self.assert_refused(_digests(override={"rustcfml-linux-x86_64": "null"}))
        self.assert_refused(_digests(override={"rustcfml-linux-x86_64": "sha512:" + "a" * 128}))
        self.assert_refused(_digests(override={"rustcfml-linux-x86_64": "sha256:" + "A" * 64}))

    def test_release_lookup_failure_leaves_every_pin(self):
        self.assert_refused(_digests(), gh_exit=1)

    def test_missing_cfc_sha256_line_leaves_every_pin(self):
        with open(self.cfc) as fh:
            cfc = fh.read()
        with open(self.cfc, "w") as fh:
            fh.write(cfc.replace('variables.engineSha256["rustcfml-linux-aarch64"]', 'variables.other["x"]'))
        out = self.assert_refused(_digests())
        self.assertIn("rustcfml-linux-aarch64", out)
        self.assertFalse(os.path.exists(self.gh_log), "the release API was queried before the pin lines were checked")

    def test_bad_tag_is_refused(self):
        self.assert_refused(_digests(), tag="latest")


if __name__ == "__main__":
    unittest.main(verbosity=2)
