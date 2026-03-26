# wheels-hotwire Plugin

## What This Is

A Wheels framework plugin providing Hotwire infrastructure: Turbo Drive, Turbo Frames, Turbo Streams, Stimulus, and Hotwire Native mobile support. This is the **interaction layer** — it has zero opinions about CSS or visual design.

This package is part of the Wheels first-party package collection, hosted in the main Wheels repository under `packages/hotwire/`. Activate by copying to `vendor/hotwire/`.

## Plugin Architecture

Standard Wheels plugin. The main CFC (`Hotwire.cfc`) contains `init()` and all public methods, which Wheels injects into controller and view scopes. Any public function defined here is callable as `#functionName()#` in views and `functionName()` in controllers.

## File Structure

```
packages/hotwire/
├── CLAUDE.md              # This file (Claude Code reads first)
├── Hotwire.cfc            # Main package CFC — ALL helpers here
├── package.json           # Package manifest
├── index.cfm              # Package UI page (Wheels debug panel)
├── box.json               # CommandBox package metadata
└── .ai/
    └── ARCHITECTURE.md    # Full architecture doc (long-form context)
```

### Single CFC Requirement

Wheels plugins inject methods from **one CFC only**. All public helper functions must be methods in `Hotwire.cfc`. Private utility methods are fine within the same CFC. Do not create separate CFCs.

## Coding Conventions

- `<cffunction>` tag syntax for all public methods
- `<cfargument>` with `required`, `type`, and `default` attributes on every parameter
- `<cfset var local = {}>` or `<cfset var ...>` for all local variables
- Function names: camelCase
- View helpers return strings (used via `#helper()#` in templates)
- Controller helpers may use `<cfset>` to call Wheels functions like `redirectTo()`
- Build multi-line HTML via `<cfsavecontent variable="local.html">` blocks
- Double quotes for HTML attributes

### Naming Patterns

- `turbo*` prefix: Turbo helpers (turboFrame, turboStreamAppend, etc.)
- `turbo*End` suffix: closing tags (turboFrameEnd)
- `hotwire*` prefix: general/native helpers (hotwireIncludes, hotwireNativeApp)
- `is*` prefix: boolean detection (isHotwireRequest, isTurboFrameRequest)
- `recede/refresh/resumeOrRedirectTo`: native navigation helpers
- `renderTurboStream`: controller method for Turbo Stream responses

## Turbo Markup Patterns

### Turbo Frame
```html
<turbo-frame id="unique-id">
    <!-- scoped content: links/forms inside update only this frame -->
</turbo-frame>

<!-- Lazy loaded -->
<turbo-frame id="unique-id" src="/path" loading="lazy">
    <p>Loading...</p>
</turbo-frame>

<!-- Targets whole page instead of frame -->
<turbo-frame id="unique-id" target="_top">
    ...
</turbo-frame>
```

### Turbo Stream Response
Content-Type MUST be `text/vnd.turbo-stream.html`. Eight actions available:
```html
<turbo-stream action="append" target="list-id">
    <template><!-- HTML to append --></template>
</turbo-stream>

<turbo-stream action="prepend" target="list-id">
    <template><!-- HTML to prepend --></template>
</turbo-stream>

<turbo-stream action="replace" target="element-id">
    <template><!-- replacement HTML (replaces entire element) --></template>
</turbo-stream>

<turbo-stream action="update" target="element-id">
    <template><!-- new inner HTML (keeps element, replaces children) --></template>
</turbo-stream>

<turbo-stream action="remove" target="element-id"></turbo-stream>

<turbo-stream action="before" target="element-id">
    <template><!-- HTML inserted before target --></template>
</turbo-stream>

<turbo-stream action="after" target="element-id">
    <template><!-- HTML inserted after target --></template>
</turbo-stream>

<turbo-stream action="refresh"></turbo-stream>
```

Multiple `<turbo-stream>` elements can be combined in a single response.

### Request Detection Headers
- **Turbo Stream**: `Accept` header contains `text/vnd.turbo-stream.html`
- **Turbo Frame**: `Turbo-Frame` header present (value = requesting frame ID)
- **Hotwire Native**: `User-Agent` contains `Turbo Native`

### Hotwire Native Navigation
After form submissions in native apps, redirect to special interception paths:
- **Recede** (pop/dismiss): `/hotwire/native/recede`
- **Refresh** (reload current screen): `/hotwire/native/refresh`
- **Resume** (do nothing): `/hotwire/native/resume`

On web requests, these helpers fall through to normal `redirectTo()` behavior.

### Path Configuration (Native)
JSON served from a known endpoint controls native app behavior:
```json
{
    "settings": {
        "tabs": [
            {"title": "Home", "path": "/dashboard", "icon": "house"},
            {"title": "Orders", "path": "/orders", "icon": "list.clipboard"}
        ]
    },
    "rules": [
        {
            "patterns": [".*"],
            "properties": { "context": "default", "pull_to_refresh_enabled": true }
        },
        {
            "patterns": ["/new$", "/edit$"],
            "properties": { "context": "modal", "pull_to_refresh_enabled": false }
        }
    ]
}
```

## Implementation Order

### Phase 1: Core (build these first)
1. `init()` — version, metadata
2. `hotwireIncludes()` — Turbo + Stimulus CDN script tags
3. `turboFrame()` / `turboFrameEnd()`
4. `isHotwireRequest()`, `isTurboFrameRequest()`, `turboFrameRequestId()`

### Phase 2: Turbo Streams
5. `turboStreamAppend()`, `turboStreamPrepend()`, `turboStreamReplace()`, `turboStreamUpdate()`, `turboStreamRemove()`, `turboStreamBefore()`, `turboStreamAfter()`, `turboStreamRefresh()`
6. `renderTurboStream()` — controller helper that sets Content-Type and outputs stream HTML
7. `$turboStreamAction()` — private helper used by all stream methods

### Phase 3: Hotwire Native
8. `hotwireNativeApp()` — User-Agent detection
9. `recedeOrRedirectTo()`, `refreshOrRedirectTo()`, `resumeOrRedirectTo()`
10. `hotwireNativePathConfiguration()` — JSON endpoint helper

### Phase 4: Stimulus Helpers (optional convenience)
11. `stimulusController()` — generates `data-controller` attribute string
12. `stimulusAction()` — generates `data-action` attribute string
13. `stimulusTarget()` — generates `data-{controller}-target` attribute string

## Testing

Test each helper by calling it with argument combinations and verifying output strings contain correct HTML. Focus on:
- Turbo Frame tag attributes (id, src, loading, target)
- Turbo Stream action validity and template wrapping
- Content-Type header setting in renderTurboStream()
- Request detection with mocked HTTP headers
- Native navigation fallback behavior (native vs. web paths)
