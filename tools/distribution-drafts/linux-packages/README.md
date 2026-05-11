# Linux packages — `.deb` / `.rpm`

Two-phase plan. Phase 1 ships the packages as GitHub Release artifacts (users
`wget` + `apt install ./pkg.deb`). Phase 2 stands up a proper apt/yum repo
served from Cloudflare Pages so users get auto-update via `apt update`.

## Phase 1: GitHub Release artifacts (in scope for Tuesday GA)

Already drafted in this directory:

- `nfpm-wheels.yaml` — stable channel package config
- `nfpm-wheels-be.yaml` — bleeding-edge channel package config
- `build-linux-packages.sh` — wrapper that stages content + runs nfpm

The build is wired into release.yml and publish-snapshot.yml as a parallel
artifact stream alongside the existing zip/tar.gz. Users on Linux who want to
opt in pre-Phase-2 do:

```bash
# Stable
curl -fsSLO https://github.com/wheels-dev/wheels/releases/download/v4.0.0/wheels_4.0.0_amd64.deb
sudo apt install ./wheels_4.0.0_amd64.deb

# Bleeding-edge — note the `.` (not `~`) in the URL; see "Tilde mangling" below
curl -fsSLO https://github.com/wheels-dev/wheels-snapshots/releases/download/v4.0.1-snapshot.1700/wheels-be_4.0.1.snapshot.1700_amd64.deb
sudo apt install ./wheels-be_4.0.1.snapshot.1700_amd64.deb
```

Same for RPM via `dnf install`.

The `~snapshot` tilde is required: `.deb` and `.rpm` use `~` (not `-`) as the
pre-release separator. The build script translates `-snapshot.N` to
`~snapshot.N` automatically. Both result in the snapshot package sorting
*below* the next GA version per `dpkg --compare-versions` and `rpmvercmp`.

### Tilde mangling on GitHub Releases (sharp edge)

The on-disk filename produced by nfpm is `wheels_4.0.0~snapshot.1787_amd64.deb`
(correct SemVer pre-release form with `~`). However, **GitHub Releases silently
rewrites `~` to `.` in uploaded asset filenames**, so the downloadable URL is
`wheels_4.0.0.snapshot.1787_amd64.deb`.

This is a one-way mangling at upload time — the URL form is the only form
consumers can `curl`. The metadata *inside* the package still contains `~`
(verifiable via `dpkg-deb -I` or `rpm -qip`), so once installed, `apt`/`dpkg`
order the version correctly relative to GA releases. Only the delivery handle
changes.

Verify on any snapshot:
```bash
gh release view v4.0.0-snapshot.1787 --repo wheels-dev/wheels-snapshots \
  --json assets -q '.assets[].name' | grep -E '\.(deb|rpm)$'
# wheels-4.0.0.snapshot.1787.x86_64.rpm
# wheels_4.0.0.snapshot.1787_amd64.deb
```

Practical impact for this directory:
- `build-linux-packages.sh` writes the `~`-form to disk (correct for nfpm and
  on-server `dpkg`). Uploading the artifact is what produces the `.`-form URL.
- Anyone publishing a download URL (docs, install scripts, brew formulae,
  Phase 2 apt repo metadata) MUST use the `.`-form or hit 404.

## Phase 2: apt.wheels.dev / yum.wheels.dev (post-Tuesday)

Two new repos (separate from the source monorepo, mirroring the snapshots-repo
pattern):

- `wheels-dev/apt-wheels-dev` — Cloudflare Pages site at `apt.wheels.dev`
- `wheels-dev/yum-wheels-dev` — Cloudflare Pages site at `yum.wheels.dev`

Each repo holds the static metadata tree (Packages.gz, repodata/, etc.) plus
the `.deb` / `.rpm` files in a `pool/` directory. A CI workflow listens for
`repository_dispatch` from the source repo's release workflows, fetches new
artifacts, regenerates metadata, signs with GPG, commits and pushes — CF Pages
auto-deploys on push.

**Filename gotcha for the metadata generator**: when fetching snapshot
artifacts from the source repo's GitHub Release, the URL filenames have `.`
where the nfpm-produced names had `~` (see "Tilde mangling" above). The
metadata generator must compute the `.`-form filename to actually fetch the
file, then either:

1. Rename to the `~`-form in `pool/` so `Packages.gz` `Filename:` fields use
   the canonical SemVer pre-release name (preferred — matches what users see
   from `apt-cache show`), or
2. Keep the `.`-form on disk in `pool/` and emit `.`-form in `Packages.gz`
   (simpler — fewer renames in the pipeline).

Either way is correct on the `apt`/`dpkg` ordering side, since the version
field inside the `.deb`'s control metadata still has `~`. Pick one and stay
consistent; option 1 reads more naturally if a user pokes around at
`apt.wheels.dev/pool/` directly.

User setup post-Phase-2:

```bash
# Debian / Ubuntu
curl -fsSL https://apt.wheels.dev/wheels.gpg \
  | sudo tee /usr/share/keyrings/wheels.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/wheels.gpg] https://apt.wheels.dev stable main" \
  | sudo tee /etc/apt/sources.list.d/wheels.list
sudo apt update && sudo apt install wheels
# For BE: replace `stable` with `bleeding-edge` in the sources line.

# Fedora / RHEL
sudo dnf config-manager --add-repo https://yum.wheels.dev/wheels.repo
sudo dnf install wheels
```

### What you'll need to do for Phase 2 (when ready)

1. **Mint a GPG signing key** for the Wheels project. Store the private key in
   1Password (or another secret store), the public key as
   `tools/distribution-drafts/linux-packages/wheels-public.gpg`.
2. **Create two CF Pages projects** pointing at:
   - `wheels-dev/apt-wheels-dev` → `apt.wheels.dev`
   - `wheels-dev/yum-wheels-dev` → `yum.wheels.dev`
3. **Add CI secrets** to `wheels-dev/wheels`:
   - `LINUX_REPO_GPG_PRIVATE_KEY` — ASCII-armored private key
   - `LINUX_REPO_GPG_PASSPHRASE` — passphrase for the private key
   - `LINUX_REPO_DISPATCH_TOKEN` — fine-grained PAT with write access to the
     two repo-bucket repos
4. **Author the repo-build workflows** in each bucket repo. Templates will be
   in `tools/distribution-drafts/apt-repo/` and `tools/distribution-drafts/yum-repo/`
   when Phase 2 lands.

### Why split into two CF Pages sites instead of one

A single site at `packages.wheels.dev/apt/...` would work but produces uglier
sources.list lines (`deb https://packages.wheels.dev/apt stable main` vs the
cleaner `deb https://apt.wheels.dev stable main`). The two-subdomain layout
matches what most projects use (Docker, Caddy, Tailscale, etc.) so it's the
form Linux admins recognize.

## Universal install script (Phase 2 polish)

Once apt/yum are live, the universal `https://wheels.dev/install.sh` script
detects the OS and runs the right setup. Pseudo-code:

```bash
case "$(uname -s)" in
  Darwin) brew install wheels ;;
  Linux)
    if command -v apt-get >/dev/null; then
      # paste the apt setup snippet
    elif command -v dnf >/dev/null; then
      # paste the yum setup snippet
    else
      # fallback: download .deb/.rpm or .tar.gz from GitHub Release
    fi
    ;;
esac
```

Hosted from a Worker on the same wheels.dev CF zone — five-minute setup once
Phase 2 is in place.
