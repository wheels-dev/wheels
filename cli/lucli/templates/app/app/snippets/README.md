# app/snippets/

Template overrides for `wheels generate`.

The generators (`wheels generate model`, `controller`, `scaffold`, `migration`, `mailer`, etc.) emit files built from `.txt` templates. When a template exists in this directory, it overrides the framework default. When it doesn't, the generator falls back to the bundled template.

## Customizing a template

1. Find the framework's version of the template you want to override in `vendor/wheels/` or the generator source.
2. Copy it into this directory with the same filename.
3. Edit to taste.

Next run of `wheels generate` picks up your override.

## Common template files

- `ModelContent.txt` — the body of a generated model
- `ControllerContent.txt` — the body of a generated controller
- `CRUDContent.txt` — the full scaffold controller
- `ActionContent.txt` — a single action stub
- `ConfigAppContent.txt` — `config/app.cfm` body
- `BoxJSON.txt` — `box.json` seed

## Notes

- Overrides are per-app. They ship with your app's repository — treat them as code.
- Overrides don't extend the generator surface. If you want a new generator command, extend the CLI instead.
