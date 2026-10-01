# app/snippets/

Per-app template overrides.

**`dbmigrate/`** holds the migration templates the development migrator UI (`/wheels/migrator`) uses to create a migration file. Edit them to change what that UI writes. (`wheels generate migration` builds its file itself and doesn't read them.)

**Generator overrides:** `wheels generate` (model, controller, view, scaffold, api-resource, …) builds files from `.txt` templates bundled with the CLI. A file with the same name in this directory overrides the bundled one, for this app only. None ships by default, so new apps always get the CLI's current templates.

## Customizing a generator template

1. Copy the bundled templates into this directory:

   ```bash
   wheels generate snippets templates
   ```

2. Delete the ones you don't want to override, and edit the rest.

The next `wheels generate` run uses your copies. An override is frozen: it won't pick up fixes when the CLI's own template changes, so keep only the ones you need.

Common ones:
- `ModelContent.txt`: a generated model
- `ControllerContent.txt`: a generated controller
- `CRUDContent.txt`: the scaffold controller
- `ViewContent.txt`: a generated view
- `ApiControllerContent.txt`: an API resource controller

## Notes

- Overrides are per-app and ship with your app's repository. Treat them as code.
- Overrides don't add generator commands. To add one, extend the CLI instead.
