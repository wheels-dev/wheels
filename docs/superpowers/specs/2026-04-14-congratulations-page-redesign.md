# Congratulations Page Redesign (A+C Hybrid)

## Summary

Replace the static, text-heavy congratulations page (`vendor/wheels/public/views/congratulations.cfm`) with a modern dashboard-style welcome page that shows runtime info, detects CLI availability, provides actionable quick-start commands, and highlights v4.0 features.

## File Changed

`vendor/wheels/public/views/congratulations.cfm` — single file rewrite. Uses existing layout wrapper (`_header.cfm` / `_footer.cfm`) and Catppuccin dark theme CSS variables already defined in `_header.cfm`.

## Design

### Section 1: Hero

Centered brand moment with dynamic runtime information.

```
W H E E L S      (spaced uppercase, subtle color)
4.0.0            (large, accent-colored version number)
[✓ Running successfully]   (green pill badge)
● Lucee 7.0.1  ● SQLite  ● Development   (environment dots)
```

Data sources:

| Data | Source |
|------|--------|
| Version | `get("version")` |
| Engine | `application.$wheels.serverName` & `application.$wheels.serverVersion` |
| Database | `application.wheels.dataSourceName` |
| Environment | `get("environment")` |

### Section 2: CLI Detection + Install Banner

**Detection:** Check for `cli/lucli/Module.cfc` in the project root:

```cfm
<cfset hasCLI = FileExists(ExpandPath("/cli/lucli/Module.cfc"))>
```

**CLI not detected** — yellow-bordered banner with tabbed install commands. OS auto-detection via `server.os.name` pre-selects the active tab:

| OS match | Pre-selected tab | Command |
|----------|-----------------|---------|
| Contains "Mac" or "Darwin" | macOS | `brew install wheels-dev/tap/wheels` |
| Contains "Linux" | Linux | `brew install wheels-dev/tap/wheels` |
| Contains "Windows" | Windows | `choco install wheels` |

All three tabs always visible; only the default selection changes. Banner text: "The Wheels CLI gives you generators, migrations, testing, and a local dev server. The commands below require it."

**CLI detected** — subtle one-line confirmation: "✓ Wheels CLI detected" in muted text.

### Section 3: Action Cards

Three cards in a `repeat(3, 1fr)` CSS grid:

| Card | Title | Description | Command |
|------|-------|-------------|---------|
| 1 | Generate a Scaffold | Create your first model, controller, and views | `wheels g scaffold Post title content:text` |
| 2 | Migrate Database | Run pending migrations to set up your schema | `wheels dbmigrate latest` |
| 3 | Run Tests | Verify your installation is working correctly | `wheels test run` |

Each card has an SVG icon, title, description, and a monospace command block.

### Section 4: Feature Grid

Six tiles in a `repeat(3, 1fr)` CSS grid, each with a tag and description:

| Feature | Tag | Description |
|---------|-----|-------------|
| Package System | New | First-party modules in vendor/ replace legacy plugins |
| Middleware | New | CORS, CSP, rate limiting, security headers |
| DI Container | New | Dependency injection with request scoping |
| Query Builder | New | Fluent, injection-safe chainable queries |
| Background Jobs | New | Async processing with retries and backoff |
| Wheels CLI | Upgraded | Zero-Docker local dev, generators, and console |

Tags use existing theme colors: green for "New", blue for "Upgraded".

### Section 5: Footer

Single flex row:
- **Left:** Documentation, Community, GitHub links
- **Right:** "Change this page → `config/routes.cfm`"

Links:
- Documentation → `https://wheels.dev`
- Community → `https://github.com/wheels-dev/wheels/discussions`
- GitHub → `https://github.com/wheels-dev/wheels`

## What Gets Removed

Everything from the current page:
- "Congratulations!" h1 and subtitle
- "Welcome to the wonderful world of Wheels" prose
- Hardcoded `3.1.0` documentation URLs
- "Hello World" tutorial link
- "How to Make this Message Go Away" numbered instructions
- `Wheels.dev` product name reference (now "Wheels")
- Font Awesome icon dependency (`fa fa-check-circle`)

## Styling Approach

No new CSS files or external dependencies. A scoped `<style>` block within the page handles:
- Hero layout and spacing
- CSS grid for action cards (3-column)
- CSS grid for feature tiles (3-column)
- CLI banner with tabbed content
- All colors reference existing `--w-*` CSS custom properties from `_header.cfm`

A small `<script>` block handles:
- OS tab switching for the CLI install banner (JavaScript, ~10 lines)

## Visual Reference

Mockup created during design: `.superpowers/brainstorm/78539-1776200777/content/hero-layout-v3.html`

## Scope

- Single file change: `vendor/wheels/public/views/congratulations.cfm`
- No changes to `_header.cfm`, `_footer.cfm`, `helpers.cfm`, or any other file
- No new dependencies
- No test changes needed (this is a static view page)
