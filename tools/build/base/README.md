# wheels-base-template

A blank, ready-to-boot [Wheels](https://wheels.dev) application.

> **Recommended path:** install the Wheels CLI (Homebrew / Scoop / apt / yum)
> and run `wheels new myapp`. The CLI substitutes app settings for you and is
> the canonical, fully documented workflow. This ForgeBox package exists for
> CommandBox users who prefer `box install`; it ships pre-substituted working
> defaults so it boots with no manual edits.

## As an Application

This is a starting point for a modern Wheels application. It uses the same
scaffold `wheels new` produces, so a `box install`-born app and a CLI-born app
are structurally identical.

## As a ForgeBox Package

This package contains the app skeleton only. The framework core is pulled in via
a dependency on `wheels-core`:

```
"dependencies":{
  "wheels-core":"4.0.3"
}
```

The core files land in `vendor/wheels/` per these settings:

```
"installPaths":{
  "wheels-core":"vendor/wheels/"
}
```

## To Install

You'll need a running [CommandBox](https://www.ortussolutions.com/products/commandbox)
installation. Then install this package into an empty directory:

```
box
mkdir myapp --cd
install wheels-base-template
```

This can be shortened to a single command run in an empty directory:

```
box install wheels-base-template
```

Then boot the server (CommandBox reads the bundled `server.json`):

```
box server start
```

`GET /` renders the Wheels welcome page. To reload after config changes, hit
`?reload=true` (the reload password defaults to empty in development — set
`reloadPassword` in `config/settings.cfm` for other environments).
