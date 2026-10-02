# Package System

Part of the Wheels application guide; start with `../CLAUDE.md`.

Optional first-party modules distributed as standalone repos and installed into `vendor/<name>/`. Auto-discovered from `vendor/*/package.json` on startup via `PackageLoader.cfc` with per-package error isolation.

```
vendor/                # Runtime: framework core + installed packages
  wheels/              #   Framework core (excluded from package discovery)
  wheels-sentry/       #   Installed package
plugins/               # DEPRECATED: legacy plugins still work with warning
```

First-party packages live in standalone repos under `wheels-dev/`, indexed by `wheels-dev/wheels-packages`:
- `wheels-sentry` — error tracking
- `wheels-hotwire` — Turbo/Stimulus
- `wheels-basecoat` — UI components
- `wheels-legacy-adapter` — 3.x → 4.x compatibility shims
- `wheels-i18n` — internationalization
- `wheels-seo-suite` — SEO tooling

## package.json Manifest

```json
{
    "name": "wheels-sentry",
    "version": "1.0.0",
    "wheelsVersion": ">=3.0",
    "mappings": {"plugins.sentry": "."},
    "provides": {"mixins": "controller", "services": [], "middleware": []},
    "requires": {}, "replaces": {}, "suggests": {}
}
```

- **`mapping`** (singular): CFML-identifier-safe alias registered as a CFML mapping. Defaults to lower-camel-case of `name`. Lets package CFCs use `new wheelsSentry.SentryClient()`.
- **`mappings`** (plural): struct of dotted aliases beyond the singular. Use for legacy compatibility paths (e.g., `plugins.sentry` keeps old call sites resolving). See [#2705](https://github.com/wheels-dev/wheels/pull/2705).
- **`provides.mixins`**: comma-delimited from `application,dispatch,controller,mapper,model,base,sqlserver,mysql,postgresql,h2,test`, plus `global` or `none`. Default `none`. View helpers belong in `controller` mixins (views execute in controller's `variables` scope).
- **`requires` / `replaces` / `suggests`**: package name → semver constraint. Loader uses these, NOT legacy `dependencies`.

## CLI

```bash
wheels packages list                  # browse registry
wheels packages search <query>
wheels packages show <name>
wheels packages add <name>            # latest compat version (canonical verb)
wheels packages add <name>@<ver>      # pin
wheels packages add <name> --force    # overwrite existing
wheels packages update <name> --yes
wheels packages update --all --yes
wheels packages remove <name>
wheels packages registry info         # registry source + cache age
wheels packages registry refresh      # bust 24h cache
```

Override registry with `WHEELS_PACKAGES_REGISTRY=<org>/<repo>` (default `wheels-dev/wheels-packages`). Restart or `wheels reload` after install. Each package loads in its own try/catch — a broken one is logged and skipped.
