# `apt-wheels` bucket repo template

This directory is the **template** for the standalone `wheels-dev/apt-wheels`
repository that backs `https://apt.wheels.dev`. The bucket repo holds the static
apt metadata tree plus the pooled `.deb` artifacts, and is auto-deployed to
Cloudflare Pages on every push.

Copy these files into the new repo when it's created — they are designed to
work out of the box once the Phase 2 operational prerequisites (GPG key,
secrets, CF Pages binding) are in place. See
[../linux-packages/README.md § Phase 2](../linux-packages/README.md) for the
end-to-end checklist.

## Contents

| File | Purpose |
|------|---------|
| `workflows/wheels-released.yml` | Receiver — listens for `repository_dispatch` (`wheels-released`) from `wheels-dev/wheels`'s release workflow, fetches the new `.deb` from the upstream GitHub Release, regenerates `Packages.gz` / `Release` / `InRelease`, signs with GPG, and commits to the bucket repo (CF Pages auto-deploys). |
| `scripts/regenerate-apt-metadata.sh` | Pure-bash wrapper around `apt-ftparchive` + `gpg --clearsign`. Idempotent — safe to re-run by hand if a release event was lost. |
| `templates/aptftparchive.conf` | apt-ftparchive config template. References the on-disk pool layout and emits `Packages` / `Release` files for each `(distribution, component, architecture)` triple. |
| `templates/index.html` | Plain-HTML landing page served at the apex (`https://apt.wheels.dev/`). Documents the sources.list snippet so users hitting the site in a browser see install instructions. |
| `templates/wheels.gpg.placeholder` | Placeholder reminding you that the **public** half of the signing key must live at `/wheels.gpg` so users can `curl https://apt.wheels.dev/wheels.gpg`. Replace with the real ASCII-armored public key. |

## Distribution layout

The bucket repo serves two distributions from the same site:

```
apt.wheels.dev/
├── wheels.gpg                       # ASCII-armored public key
├── dists/
│   ├── stable/
│   │   ├── Release
│   │   ├── Release.gpg
│   │   ├── InRelease                # inline-signed Release (preferred)
│   │   └── main/
│   │       └── binary-amd64/
│   │           ├── Packages
│   │           └── Packages.gz
│   └── bleeding-edge/
│       └── ... (mirror of the stable tree)
└── pool/
    ├── stable/
    │   └── w/wheels/wheels_<v>_amd64.deb
    └── bleeding-edge/
        └── w/wheels-be/wheels-be_<v>_amd64.deb
```

User-facing setup post-Phase-2:

```bash
# Stable
curl -fsSL https://apt.wheels.dev/wheels.gpg \
  | sudo tee /usr/share/keyrings/wheels.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/wheels.gpg] https://apt.wheels.dev stable main" \
  | sudo tee /etc/apt/sources.list.d/wheels.list
sudo apt update && sudo apt install wheels

# Bleeding-edge — note: package name is `wheels-be`, not `wheels`,
# so the two channels can coexist on the same host.
echo "deb [signed-by=/usr/share/keyrings/wheels.gpg] https://apt.wheels.dev bleeding-edge main" \
  | sudo tee /etc/apt/sources.list.d/wheels-be.list
sudo apt update && sudo apt install wheels-be
```

## Package name & channel convention

| Channel | Package name in `.deb` | Pool path | `apt install` invocation |
|---------|------------------------|-----------|--------------------------|
| Stable | `wheels` | `pool/stable/w/wheels/` | `apt install wheels` |
| Bleeding-edge | `wheels-be` | `pool/bleeding-edge/w/wheels-be/` | `apt install wheels-be` |

This mirrors the existing direct-install behaviour (you `apt install
./wheels-be_*.deb` on BE today; Phase 2 just gives it a stable URL). The
distinct names mean stable and BE can be installed side-by-side on the same
host — useful for users who want a working stable CLI alongside a BE one for
testing.

## Filename: `~`-form vs `.`-form

GitHub Releases silently rewrites `~` to `.` in uploaded asset filenames, so:

- On disk locally (nfpm output): `wheels-be_4.0.1~snapshot.1787_amd64.deb`
- GitHub Release URL: `wheels-be_4.0.1.snapshot.1787_amd64.deb`
- Pool path (this repo): `pool/bleeding-edge/w/wheels-be/wheels-be_4.0.1~snapshot.1787_amd64.deb`

The receiver workflow downloads using the `.`-form (the only form the GitHub
Release URL exposes), then renames to the canonical `~`-form before publishing
into the pool. The version field *inside* the `.deb` metadata always carries
`~`, so `dpkg --compare-versions` orders snapshot releases below the next GA
release correctly regardless of which form sits in `pool/`.

Documented in [`build-linux-packages.sh:167`](../linux-packages/build-linux-packages.sh).

## Operational prerequisites

Before this bucket repo will function:

1. **GPG signing key** — generate a 4096-bit RSA key (or Ed25519 if you prefer)
   for `Wheels Distribution <hello@wheels.dev>`. Private key + passphrase go
   into 1Password under `op://Wheels/wheels-linux-repo-signing/` (Wheels
   project vault on `my.1password.com`).
   Public key (ASCII-armored) overwrites `wheels.gpg` at the bucket-repo root.
2. **Cloudflare Pages** — create a Pages project pointing at this repo, bind
   the apex domain `apt.wheels.dev`. The build command is empty (the repo
   *is* the static site); the output dir is `./`.
3. **CI secrets** (set on the bucket repo at
   `https://github.com/wheels-dev/apt-wheels/settings/secrets/actions`):
   - `WHEELS_REPO_GPG_PRIVATE_KEY` — ASCII-armored private key
   - `WHEELS_REPO_GPG_PASSPHRASE` — passphrase
4. **Upstream dispatch** — the release workflow in `wheels-dev/wheels`
   fires a `repository_dispatch` (`wheels-released`) at this repo when a
   new `.deb` is published to the GitHub Release. The token used by the
   sender (`LINUX_REPO_DISPATCH_TOKEN` on `wheels-dev/wheels`) must have
   `actions: write` on this repo.

## Verifying

```bash
# From a fresh Debian/Ubuntu host:
curl -fsSL https://apt.wheels.dev/wheels.gpg \
  | sudo tee /usr/share/keyrings/wheels.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/wheels.gpg] https://apt.wheels.dev stable main" \
  | sudo tee /etc/apt/sources.list.d/wheels.list
sudo apt update
sudo apt-cache policy wheels   # should show the apt.wheels.dev origin
sudo apt install wheels
wheels --version
```

`apt update` reports `Get:N https://apt.wheels.dev stable InRelease` on
success. A `NO_PUBKEY` error means the public key wasn't installed at
`/usr/share/keyrings/wheels.gpg` (or it doesn't match the key the bucket
signed with — `apt-key list` no longer applies; check
`gpg --no-default-keyring --keyring /usr/share/keyrings/wheels.gpg --list-keys`).
