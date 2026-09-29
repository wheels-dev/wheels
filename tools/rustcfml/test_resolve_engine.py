#!/usr/bin/env python3
"""Tests for how run-suite.sh resolves and verifies the RustCFML engine binary.

Runs the top of tools/rustcfml/run-suite.sh (everything before it starts the
server) from a scratch copy of the pinned files, with a fake `gh` (release API
and download) and a fake `uname` on PATH, so it needs no engine or network:

    python3 tools/rustcfml/test_resolve_engine.py
"""

import hashlib
import os
import shutil
import stat
import subprocess
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SERVE_MARKER = "# --- serve the repo webroot"

GOOD = b"good engine build\n"
BAD = b"some other build\n"
GOOD_SHA = hashlib.sha256(GOOD).hexdigest()
BAD_SHA = hashlib.sha256(BAD).hexdigest()
ASSET = "rustcfml-linux-x86_64"

FAKE_GH = """#!/usr/bin/env bash
echo "$*" >> "$FAKE_GH_LOG"
case "$1" in
  api) cat "$FAKE_GH_DIGESTS" ;;
  release)
    out=""
    while [ $# -gt 0 ]; do
      [ "$1" = "--output" ] && out="$2"
      shift
    done
    cp "$FAKE_GH_ASSET" "$out" ;;
  *) exit 99 ;;
esac
"""

FAKE_UNAME = """#!/usr/bin/env bash
case "$1" in
  -s) echo "$FAKE_UNAME_S" ;;
  -m) echo "$FAKE_UNAME_M" ;;
  *) echo "$FAKE_UNAME_S" ;;
esac
"""


def _resolve_source():
    """run-suite.sh up to (not including) the part that starts the engine."""
    with open(os.path.join(HERE, "run-suite.sh"), encoding="utf-8") as fh:
        text = fh.read()
    return text[:text.index(SERVE_MARKER)]


def _write_exe(path, body):
    with open(path, "w") as fh:
        fh.write(body)
    os.chmod(path, os.stat(path).st_mode | stat.S_IEXEC)


class ResolveEngineTest(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.tools = os.path.join(self.tmp, "tools", "rustcfml")
        os.makedirs(self.tools)
        for name in ("engine-sha256.sh", "ENGINE_VERSION"):
            shutil.copy(os.path.join(HERE, name), self.tools)
        with open(os.path.join(self.tools, "ENGINE_VERSION")) as fh:
            self.pinned = fh.read().strip()
        # The pinned sha256 for the linux-x86_64 asset is GOOD's.
        self.write_pins({ASSET: GOOD_SHA, "rustcfml-macos-aarch64": "c" * 64})
        self.script = os.path.join(self.tools, "run-suite.sh")
        with open(self.script, "w") as fh:
            fh.write(_resolve_source())
        self.bin = os.path.join(self.tmp, "bin")
        os.makedirs(self.bin)
        _write_exe(os.path.join(self.bin, "gh"), FAKE_GH)
        _write_exe(os.path.join(self.bin, "uname"), FAKE_UNAME)
        self.cache = os.path.join(self.tmp, "cache")
        self.gh_log = os.path.join(self.tmp, "gh.log")

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def write_pins(self, pins):
        with open(os.path.join(self.tools, "ENGINE_SHA256"), "w") as fh:
            fh.write("".join("%s  %s\n" % (sha, asset) for asset, sha in pins.items()))

    def resolve(self, asset=GOOD, version=None, digests="", platform=("Linux", "x86_64"),
                engine_bin=None):
        asset_path = os.path.join(self.tmp, "asset")
        with open(asset_path, "wb") as fh:
            fh.write(asset)
        digests_path = os.path.join(self.tmp, "digests.txt")
        with open(digests_path, "w") as fh:
            fh.write(digests)
        env = dict(os.environ, PATH=self.bin + os.pathsep + os.environ["PATH"],
                   RUSTCFML_CACHE_DIR=self.cache, FAKE_GH_LOG=self.gh_log,
                   FAKE_GH_ASSET=asset_path, FAKE_GH_DIGESTS=digests_path,
                   FAKE_UNAME_S=platform[0], FAKE_UNAME_M=platform[1])
        for key in ("RUSTCFML_VERSION", "RUSTCFML_BIN"):
            env.pop(key, None)
        if version:
            env["RUSTCFML_VERSION"] = version
        if engine_bin:
            env["RUSTCFML_BIN"] = engine_bin
        proc = subprocess.run(["bash", self.script], capture_output=True, text=True, env=env)
        return proc.returncode, proc.stdout + proc.stderr

    def gh_calls(self):
        if not os.path.exists(self.gh_log):
            return []
        with open(self.gh_log) as fh:
            return fh.read().splitlines()

    def downloads(self):
        return [c for c in self.gh_calls() if c.startswith("release download")]

    def cache_entries(self):
        return sorted(os.listdir(self.cache)) if os.path.isdir(self.cache) else []

    def assert_installed(self, version, out):
        path = os.path.join(self.cache, "rustcfml-" + version)
        with open(path, "rb") as fh:
            self.assertEqual(fh.read(), GOOD, out)
        self.assertTrue(os.access(path, os.X_OK), out)
        self.assertEqual(self.cache_entries(), ["rustcfml-" + version], out)
        self.assertIn("Engine: " + path, out)

    # --- pinned version: sha256 from ENGINE_SHA256 ---------------------------

    def test_pinned_matching_download_installs(self):
        code, out = self.resolve()
        self.assertEqual(code, 0, out)
        self.assert_installed(self.pinned, out)
        self.assertEqual(len(self.downloads()), 1, self.gh_calls())
        self.assertFalse([c for c in self.gh_calls() if c.startswith("api")],
                         "the pinned version must not need the release API")

    def test_pinned_mismatched_download_exits_1_and_leaves_nothing(self):
        code, out = self.resolve(asset=BAD)
        self.assertEqual(code, 1, out)
        self.assertEqual(self.cache_entries(), [], out)
        self.assertIn(GOOD_SHA, out)
        self.assertIn(BAD_SHA, out)

    def test_cached_binary_with_wrong_hash_is_replaced(self):
        os.makedirs(self.cache)
        cached = os.path.join(self.cache, "rustcfml-" + self.pinned)
        with open(cached, "wb") as fh:
            fh.write(BAD)
        os.chmod(cached, 0o755)
        code, out = self.resolve()
        self.assertEqual(code, 0, out)
        self.assert_installed(self.pinned, out)
        self.assertEqual(len(self.downloads()), 1, self.gh_calls())

    def test_cached_binary_with_right_hash_is_reused(self):
        os.makedirs(self.cache)
        cached = os.path.join(self.cache, "rustcfml-" + self.pinned)
        with open(cached, "wb") as fh:
            fh.write(GOOD)
        os.chmod(cached, 0o755)
        code, out = self.resolve(asset=BAD)
        self.assertEqual(code, 0, out)
        self.assert_installed(self.pinned, out)
        self.assertEqual(self.downloads(), [])

    def test_pinned_asset_without_pin_line_exits_1_without_downloading(self):
        # No macOS Intel build exists, so there is no pin for its asset name.
        code, out = self.resolve(platform=("Darwin", "x86_64"))
        self.assertEqual(code, 1, out)
        self.assertIn("rustcfml-macos-x86_64", out)
        self.assertEqual(self.downloads(), [])
        self.assertEqual(self.cache_entries(), [])

    # --- candidate version: sha256 from the release's API digest ------------

    def digests(self, digest):
        return ("LICENSE sha256:%s\n%s %s\nrustcfml-macos-aarch64 sha256:%s\n"
                % ("0" * 64, ASSET, digest, "d" * 64))

    def test_candidate_uses_the_api_digest(self):
        # ENGINE_SHA256 holds a different sha256; the candidate's own digest wins.
        self.write_pins({ASSET: "a" * 64})
        code, out = self.resolve(version="v9.9.9", digests=self.digests("sha256:" + GOOD_SHA))
        self.assertEqual(code, 0, out)
        self.assert_installed("v9.9.9", out)
        self.assertIn("api repos/RustCFML/RustCFML/releases/tags/v9.9.9", " ".join(self.gh_calls()))

    def test_candidate_mismatched_download_exits_1(self):
        code, out = self.resolve(version="v9.9.9", asset=BAD,
                                 digests=self.digests("sha256:" + GOOD_SHA))
        self.assertEqual(code, 1, out)
        self.assertEqual(self.cache_entries(), [], out)

    def test_candidate_without_a_usable_digest_exits_1_without_downloading(self):
        for digests in ("LICENSE sha256:%s\n" % ("0" * 64),
                        self.digests("null"),
                        self.digests("sha256:" + GOOD_SHA.upper()),
                        self.digests("sha512:" + "a" * 128),
                        self.digests("sha256:" + GOOD_SHA) + "%s sha256:%s\n" % (ASSET, "b" * 64)):
            with self.subTest(digests=digests):
                if os.path.exists(self.gh_log):
                    os.remove(self.gh_log)
                code, out = self.resolve(version="v9.9.9", digests=digests)
                self.assertEqual(code, 1, out)
                self.assertEqual(self.downloads(), [], out)
                self.assertEqual(self.cache_entries(), [], out)

    # --- explicit local binary ----------------------------------------------

    def test_explicit_binary_is_used_as_is(self):
        local = os.path.join(self.tmp, "my-rustcfml")
        _write_exe(local, "#!/bin/sh\n")
        code, out = self.resolve(engine_bin=local)
        self.assertEqual(code, 0, out)
        self.assertIn("Engine: " + local, out)
        self.assertEqual(self.gh_calls(), [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
