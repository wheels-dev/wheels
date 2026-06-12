# Wheels CLI Commands (DEPRECATED)

> **DEPRECATED — do not use for new projects.** This legacy CommandBox
> `wheels-cli` module does not support Wheels 4.0+ and is scheduled for removal
> in v5.0 (issues [#2227](https://github.com/wheels-dev/wheels/issues/2227),
> [#2634](https://github.com/wheels-dev/wheels/issues/2634)). Install the
> supported Wheels CLI instead:
>
> ```bash
> brew install wheels-dev/wheels/wheels
> ```
>
> Other platforms (scoop / apt / yum) and full instructions:
> <https://guides.wheels.dev/v4-0-0/command-line-tools/installation/>

This package is still published to ForgeBox **only** so existing automation
that runs `box install wheels-cli` keeps working. It receives no new features,
is not maintained for Wheels 4.0+, and will be removed in v5.0.

## Supported CLI

The supported command-line tool is the standalone `wheels` binary (built on the
LuCLI runtime). Install it once and it manages every Wheels project:

```bash
brew install wheels-dev/wheels/wheels
```

Installation for scoop, apt, and yum is documented in the install guide:
<https://guides.wheels.dev/v4-0-0/command-line-tools/installation/>

Migrating off this legacy module is covered in the 3.x → 4.x upgrade guide:
<https://guides.wheels.dev/v4-0-0/upgrading/3x-to-4x/>

## Legacy installation (existing automation only)

If you have existing automation pinned to this module, it continues to install
via CommandBox:

```bash
box install wheels-cli
```

Do not adopt this for new projects — use the supported `wheels` binary above.

## License

Apache License 2.0
