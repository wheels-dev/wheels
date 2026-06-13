# DEPRECATED — Legacy CommandBox `wheels-cli` module (FROZEN)

> **This module is frozen and no longer published.** It does not know about
> Wheels 4.0+ and drifts from the supported Wheels CLI. Do not use it for new
> work, and do not extend it.

This directory (`cli/src/`) is the source of the legacy CommandBox `wheels-cli`
module — the one historically installed via:

```bash
box install wheels-cli
```

As of [#3184](https://github.com/wheels-dev/wheels/issues/3184) the release
pipeline **no longer prepares, validates, builds, or publishes** this module to
ForgeBox. The last published version on ForgeBox (`wheels-cli@4.0.3`) is left in
place but will not advance. See [#3180](https://github.com/wheels-dev/wheels/issues/3180)
for why the two CLIs diverged (e.g. the legacy generator leaked an unrendered
`{{enums}}` placeholder into generated models that the supported CLI renders
correctly).

## Use the supported Wheels CLI instead

The canonical Wheels 4.0+ CLI is the LuCLI-based `wheels` binary
(`cli/lucli/`), distributed through your platform package manager — **not**
CommandBox/ForgeBox:

```bash
# macOS / Linux (Homebrew)
brew install wheels-dev/wheels/wheels

# Windows (Scoop)
scoop bucket add wheels-dev https://github.com/wheels-dev/scoop-wheels
scoop install wheels

# Linux (apt) — Debian/Ubuntu
#   see https://apt.wheels.dev for the signed repo setup

# Linux (yum/dnf) — RHEL/Rocky/Fedora
#   see https://yum.wheels.dev for the signed repo setup
```

Then scaffold a new application:

```bash
wheels new myapp
```

Install docs: <https://guides.wheels.dev/v4-0-0/command-line-tools/installation/>
The deprecation timeline (removal scheduled for v5.0) is documented in the
[3.x → 4.x upgrade guide](https://guides.wheels.dev/v4-0-0/upgrading/3x-to-4x/)
under "Legacy CommandBox `wheels-cli` module" (#2227, #2634).

## Note for maintainers

`cli/src/templates/` is still consumed by the canonical LuCLI module build (the
release pipeline copies it into `cli/lucli/templates/codegen/` — see
`.github/workflows/release.yml` "Build Wheels Module Tarball", #1944). Freezing
the CommandBox *distribution* does not make `cli/src/templates/` dead code.
Everything else under `cli/src/` (`commands/`, `models/`, `interceptors/`,
`recipes/`, `ModuleConfig.cfc`) is frozen legacy and should not receive new
features. Removal is tracked for v5.0.
