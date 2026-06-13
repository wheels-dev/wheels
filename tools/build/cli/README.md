# Wheels CLI — DEPRECATED & FROZEN

> **This CommandBox module is deprecated and frozen.** It does not know about
> Wheels 4.0+ and drifts from the supported Wheels CLI. The Wheels release
> pipeline no longer publishes it (#3184); the last ForgeBox version
> (`wheels-cli@4.0.3`) is left in place but will not advance. **Do not install
> it for new work.**

## Use the supported Wheels CLI instead

The canonical Wheels 4.0+ CLI is the LuCLI-based `wheels` binary, distributed
through your platform package manager — **not** `box install`:

```bash
# macOS / Linux (Homebrew)
brew install wheels-dev/wheels/wheels

# Windows (Scoop)
scoop bucket add wheels-dev https://github.com/wheels-dev/scoop-wheels
scoop install wheels

# Linux apt:  https://apt.wheels.dev
# Linux yum:  https://yum.wheels.dev
```

Create a new Wheels application:

```bash
wheels new myapp
```

Full install docs:
<https://guides.wheels.dev/v4-0-0/command-line-tools/installation/>

The deprecation timeline (removal scheduled for v5.0) is in the
[3.x → 4.x upgrade guide](https://guides.wheels.dev/v4-0-0/upgrading/3x-to-4x/)
under "Legacy CommandBox `wheels-cli` module" (#2227, #2634, #3180, #3184).

## License

Apache License 2.0
