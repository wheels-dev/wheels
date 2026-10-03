# IIS (Windows) test job

`.github/workflows/iis-windows.yml` runs a Wheels app behind IIS on `windows-latest` and reports which IIS rewrite rules hold. It's a test-only workflow and not a required check. It runs on `workflow_dispatch` and on pull requests that touch these files, `public/urlrewrite.xml` or the v4.2 IIS guide.

## Stack
- **Downloads:** each one is pinned by SHA-256 in `install.ps1`.
- **IIS:** with ASP.NET 4.5, which BonCode's managed handler needs, and **URL Rewrite 2.1**.
- **Lucee 7 Express:** Tomcat, with AJP bound to `127.0.0.1:8009`. There is one Tomcat context for the root app and one for `/app1`.
- **BonCode** IIS-to-Tomcat connector 1.0.50, installed globally in silent mode with the CFML handlers. Lucee reads BonCode's path-info header, so `/index.cfm/...` routing works.
- **Out of scope:** Adobe ColdFusion, since it needs a licensed installer.

## Apps and variants
`deploy.ps1` builds two copies of the repository's app on the runner. The fixture routes and the `Probes` controller in `fixture/` are copied in at job time, so the repo's own `app/` and `config/` are unchanged.
- `C:\wheels-iis\root`: the IIS site root.
- `C:\wheels-iis\app1`: an IIS application at `/app1`, with `set(subpath="/app1")` and its own application name.

`checks.ps1` puts each `web.config` in place and runs the same checks:

| Variant | web.config | Served at |
|---|---|---|
| `guide` | the inline rule from the v4.2 IIS guide (`web.config.guide`, extracted from the page) | `/` |
| `root` | `web.config.root` | `/` |
| `subfolder` | `web.config.subfolder` | `/app1` |

## Checks
| Check | Expected |
|---|---|
| `index.cfm` directly; home; path info (`/index.cfm/...`) | 200 |
| Pretty URL; nested route | 200 and the probe text |
| Static asset under `stylesheets/` | 200, served as a file |
| Unknown route | 404 |
| Route named like a static folder (`/files-gallery`) | routed to Wheels |
| Dev tools (`/wheels/info`) from loopback | 200 |
| Dev tools from the runner's non-loopback address | 403 |
| Reload back to the page | redirects to the page, subfolder included |
| Reload with a `//`-leading path | redirects to a path in the app |
| `/app1` without a trailing slash | home or a redirect (subfolder only) |

A check marked INFO records a known gap without failing the job. Results go to the job summary and the `iis-report` artifact.

## Findings
- **Root and subfolder `web.config`:** every check holds.
- **The guide's inline rule:**
  - **Holds:** the core routing, static files, 404s, the dev-tools gate and the reload redirect.
  - **Gap (INFO):** its `{REQUEST_URI}` prefix list has no folder boundary, so a route such as `/files-gallery` (starting like the `files` folder) isn't rewritten, and IIS answers 404. `web.config.root` ends the match at a folder boundary instead: `(/.*)?$`.
- **Reload redirect under `/app1`:** it dropped the subfolder for a running app. That was found by this job and fixed in #4140.
