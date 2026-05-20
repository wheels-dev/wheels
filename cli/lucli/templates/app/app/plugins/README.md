# app/plugins/

**Legacy plugin drop-in (deprecated in v4.0).**

Wheels 3.x used this directory for the plugin system. For v4.0 and beyond, plugins have been replaced by **packages** under `vendor/`.

## What to use instead

Install a package into `vendor/<name>/`. First-party packages live under `wheels-dev/` on GitHub and are indexed by the [`wheels-dev/wheels-packages`](https://github.com/wheels-dev/wheels-packages) registry.

Add a package to your app:

```bash
wheels packages add wheels-hotwire
wheels stop && wheels start
```

Note: the install verb is `add`, not `install`.

See [Packages](https://wheels.dev/v4-0-0-snapshot/digging-deeper/) in the guides for details.

## Migrating from a 3.x plugin

If you have an existing plugin here from a 3.x upgrade:

1. Read the plugin's code — many can be moved into `app/lib/` as regular CFCs.
2. If it provides middleware, migrate to the middleware pipeline (`config/settings.cfm` → `set(middleware = [...])`).
3. If it provides cross-cutting mixins (controller/model/view), wrap it as a package with a `package.json` declaring `provides.mixins`.

Plugins still load during app boot, so existing code keeps working — this directory stays functional. New code should go under `app/lib/` or a package under `vendor/`.
