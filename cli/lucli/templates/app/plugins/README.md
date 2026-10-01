# plugins/

**Legacy plugin drop-in (deprecated in v4.0, removed in v5.0).**

Wheels 3.x loaded plugins from this directory, and 4.x still does: the framework maps `/plugins` to this folder (see `public/Application.cfc`) and loads any plugin placed here at app boot, logging a deprecation warning. New code shouldn't use it.

## What to use instead

Install a package into `vendor/<name>/`. First-party packages live under `wheels-dev/` on GitHub and are indexed by the [`wheels-dev/wheels-packages`](https://github.com/wheels-dev/wheels-packages) registry.

Add a package to your app:

```bash
wheels packages add wheels-hotwire
wheels stop && wheels start
```

Note: the install verb is `add`, not `install`.

See [Packages](https://guides.wheels.dev/v4-1-0/digging-deeper/packages/) in the guides for details.

## Migrating from a 3.x plugin

If you have an existing plugin from a 3.x app, it keeps working here for now. To move off it:

1. Read the plugin's code. Many can be moved into `app/lib/` as regular CFCs.
2. If it provides middleware, move it to `app/middleware/` and the middleware pipeline (`config/settings.cfm` → `set(middleware = [...])`).
3. If it provides cross-cutting mixins (controller/model/view), wrap it as a package with a `package.json` declaring `provides.mixins`.
