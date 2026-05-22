# `yum-wheels` bucket repo template

This directory is the **template** for the standalone `wheels-dev/yum-wheels`
repository that backs `https://yum.wheels.dev`. The bucket repo holds the
static yum metadata tree plus the pooled `.rpm` artifacts, and is auto-deployed
to Cloudflare Pages on every push.

Copy these files into the new repo when it's created — they are designed to
work out of the box once the Phase 2 operational prerequisites (GPG key,
secrets, CF Pages binding) are in place. See
[../linux-packages/README.md § Phase 2](../linux-packages/README.md) for the
end-to-end checklist.

## Contents

| File | Purpose |
|------|---------|
| `workflows/wheels-released.yml` | Receiver — listens for `repository_dispatch` (`wheels-released`) from `wheels-dev/wheels`'s release workflow, fetches the new `.rpm` from the upstream GitHub Release, regenerates `repodata/repomd.xml` via `createrepo_c`, signs with GPG, and commits to the bucket repo. |
| `scripts/regenerate-yum-metadata.sh` | Pure-bash wrapper around `createrepo_c` + `gpg --detach-sign`. Idempotent. |
| `templates/wheels.repo` | The `.repo` file users grab via `dnf config-manager --add-repo`. Hosted at `https://yum.wheels.dev/wheels.repo`. |
| `templates/wheels-be.repo` | Bleeding-edge variant of the `.repo` file. |
| `templates/index.html` | Plain-HTML landing page served at the apex (`https://yum.wheels.dev/`). |
| `templates/wheels.gpg.placeholder` | Reminder that the **public** half of the signing key must live at `/wheels.gpg`. |

## Distribution layout

Two distributions, single GPG key, parallel to the apt repo:

```
yum.wheels.dev/
├── wheels.gpg                                       # ASCII-armored public key
├── wheels.repo                                      # stable channel .repo file
├── wheels-be.repo                                   # bleeding-edge .repo file
├── stable/
│   ├── repodata/
│   │   ├── repomd.xml
│   │   ├── repomd.xml.asc                           # detached GPG signature
│   │   ├── repomd.xml.key                           # public key copy (some clients fetch this)
│   │   ├── primary.xml.gz
│   │   ├── filelists.xml.gz
│   │   └── other.xml.gz
│   └── packages/
│       └── wheels-<v>.x86_64.rpm
└── bleeding-edge/
    └── ... (mirror of the stable tree)
```

User-facing setup post-Phase-2:

```bash
# Stable
sudo dnf config-manager --add-repo https://yum.wheels.dev/wheels.repo
sudo dnf install wheels

# Bleeding-edge — distinct package name (`wheels-be`) so it coexists with stable
sudo dnf config-manager --add-repo https://yum.wheels.dev/wheels-be.repo
sudo dnf install wheels-be
```

## Package name & channel convention

Identical to the apt side:

| Channel | Package name | Pool path | `dnf install` invocation |
|---------|--------------|-----------|--------------------------|
| Stable | `wheels` | `stable/packages/` | `dnf install wheels` |
| Bleeding-edge | `wheels-be` | `bleeding-edge/packages/` | `dnf install wheels-be` |

## Filename: `~`-form vs `.`-form

Same gotcha as apt — GitHub Releases rewrites `~` to `.` on upload. The
receiver workflow downloads the `.`-form (the only form the GitHub Release
URL exposes), then renames to the canonical `~`-form before slotting into
`packages/`. The version field *inside* the RPM metadata always carries `~`,
so `rpmvercmp` orders snapshot releases below the next GA correctly.

## Operational prerequisites

Same GPG key as the apt repo (one key for both, importable on both clients
via `https://apt.wheels.dev/wheels.gpg` or `https://yum.wheels.dev/wheels.gpg`).

CI secrets on `https://github.com/wheels-dev/yum-wheels/settings/secrets/actions`:
- `WHEELS_REPO_GPG_PRIVATE_KEY` — ASCII-armored private key
- `WHEELS_REPO_GPG_PASSPHRASE` — passphrase

The upstream dispatch token (`LINUX_REPO_DISPATCH_TOKEN` on
`wheels-dev/wheels`) must have `actions: write` on this repo.

## Verifying

```bash
# From a fresh Fedora/RHEL host:
sudo dnf config-manager --add-repo https://yum.wheels.dev/wheels.repo
sudo dnf install wheels
wheels --version
# To verify GPG signing is actually happening (the .repo file has gpgcheck=1):
sudo dnf --refresh check-update wheels
# yum/dnf prints "Importing GPG key 0x<keyid>: ..." on first refresh.
```

A `repomd.xml.asc verify failed` error means the bucket's GPG signing step
didn't run, or the public key at `/wheels.gpg` doesn't match the private key
that signed.
