# Upgrading

Part of the Wheels application guide; start with `../CLAUDE.md`.

Run `wheels upgrade check` first: it scans the app read-only and lists what breaks on the way to the target version (`--to=<version>`, `--format=json`, `--strict` to fail on advisories too, `--offline` together with `--to`). Breaking findings exit non-zero. `wheels upgrade apply --to=<version>` swaps the framework afterwards.

Full guides: https://guides.wheels.dev/v4-2-0/upgrading/ (3.x to 4.x, 4.0 to 4.1, 4.1 to 4.2).

## APIs that changed in 4.x

| Old | Now | Since | Old code |
|---|---|---|---|
| `application.wirebox` | `service("name")` (or `injector()` for the container; the scope key is `application.wheelsdi`) | 4.0 | Undefined key error; WireBox is no longer bundled. |
| `paginationLinks()` | `paginationNav()` and the composable pagination helpers (`.ai/views.md`) | 4.0 | Still works, logs a one-time deprecation warning. |
| `findAll(returnAs="structs")` returning a struct keyed by row number | An array of structs | 4.2 | `rows[1]` still works; `StructCount` / `StructKeyList` / `for (key in rows)` don't. `returnAs="array"` behaves the same on 4.1 and 4.2. |
| Any `joinType` on an association | `inner`, `outer`, `left` or `left outer` (case-insensitive) | 4.2 | Anything else throws `Wheels.InvalidJoinType` when the model loads. |
| An action named `renderNotFound` or `isSafeRedirectUrl` | Rename the action | 4.2 | Both are now public framework helpers, and an action named after a framework helper returns a 404. |
| `renderPage()` / `renderPageToString()` | `renderView()` / `renderView(returnAs="string")` | 2.0 | Undefined function; check very old code for it. |

Guides: [3.x to 4.x](https://guides.wheels.dev/v4-2-0/upgrading/3x-to-4x/), [4.1 to 4.2](https://guides.wheels.dev/v4-2-0/upgrading/4x-1-to-4x-2/), [`wheels upgrade`](https://guides.wheels.dev/v4-2-0/command-line-tools/wheels-commands/upgrade/).
