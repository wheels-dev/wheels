#!/usr/bin/env python3
"""Refuse to republish a released version (#4221).

release.yml runs on every push to main and publishes the version wheels.json
names. If that version was already released, the run used to rebuild it and
replace the published assets in place (v4.1.0 was rebuilt on 2026-09-17), and
republish it to ForgeBox. A published version's assets must never change, so
release.yml runs this before any build or publish step:

    release_republish_guard.py --repo OWNER/REPO --tag vX.Y.Z --sha COMMIT

Exit 0 lets the release proceed, exit 1 stops it. The decision:

- a release for the tag exists with at least one asset: stop (bump the version;
  a partial upload from a failed run must be deleted by hand first);
- the tag exists at another commit: stop (a new build must not be attached to
  an existing tag);
- otherwise proceed: no release and no tag yet, or an empty release / bare tag
  on this same commit, which is a run that failed before uploading anything.

It fails closed: any lookup error other than "not found" stops the release.
The GitHub API is read through `gh api` (GH_BIN overrides the binary, which is
how the tests substitute canned responses).
"""
import argparse
import os
import subprocess
import sys

OK, ABSENT, ERROR = "ok", "absent", "error"


def lookup(path, jq, absent_markers):
    """Run `gh api PATH --jq JQ`. Returns (OK, value), (ABSENT, None) or (ERROR, detail)."""
    cmd = [os.environ.get("GH_BIN", "gh"), "api", path, "--jq", jq]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return ERROR, str(exc)
    if proc.returncode == 0:
        return OK, proc.stdout.strip()
    detail = proc.stderr.strip()
    if any(marker in detail for marker in absent_markers):
        return ABSENT, None
    return ERROR, detail or "gh api exited %d with no message" % proc.returncode


def decide(tag, sha, release, tag_commit):
    """Return (exit_code, lines). release / tag_commit are lookup() results."""
    lines = []
    status, value = release
    if status == ERROR:
        return 1, ["::error::Could not check for an existing %s release (%s); "
                   "refusing to publish without that check." % (tag, value)]
    if status == OK:
        try:
            assets = int(value)
        except ValueError:
            return 1, ["::error::Unexpected asset count %r for release %s; refusing to publish." % (value, tag)]
        if assets > 0:
            return 1, ["::error::Release %s is already published with %d assets. A published version's "
                       "assets never change: bump the version in wheels.json for this change. If %s is a "
                       "partial upload from a failed run, delete that release by hand first, then re-run."
                       % (tag, assets, tag)]
        lines.append("Release %s exists with no assets (an earlier run failed before uploading)." % tag)
    else:
        lines.append("No release for %s yet." % tag)

    status, value = tag_commit
    if status == ERROR:
        return 1, lines + ["::error::Could not check tag %s (%s); refusing to publish without that check."
                           % (tag, value)]
    if status == OK:
        if value != sha:
            return 1, lines + ["::error::Tag %s already points at %s, not this commit (%s). Bump the version "
                               "in wheels.json; a new build must not be attached to an existing tag."
                               % (tag, value, sha)]
        lines.append("Tag %s points at this commit." % tag)
    else:
        lines.append("No tag %s yet." % tag)
    return 0, lines


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--repo", required=True)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--sha", required=True)
    args = parser.parse_args(argv)

    release = lookup("repos/%s/releases/tags/%s" % (args.repo, args.tag), ".assets | length", ["HTTP 404"])
    tag_commit = lookup("repos/%s/commits/%s" % (args.repo, args.tag), ".sha", ["HTTP 404", "No commit found"])
    code, lines = decide(args.tag, args.sha, release, tag_commit)
    for line in lines:
        print(line)
    return code


if __name__ == "__main__":
    sys.exit(main())
