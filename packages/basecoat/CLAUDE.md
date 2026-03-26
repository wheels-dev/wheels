# wheels-basecoat Plugin

## What This Is

A Wheels framework plugin providing CFML view helpers that generate Basecoat UI component markup — shadcn/ui-quality design using plain HTML + Tailwind CSS classes. No React, no build step. Works with or without wheels-hotwire.

This package is part of the Wheels first-party package collection, hosted in the main Wheels repository under `packages/basecoat/`. Activate by copying to `vendor/basecoat/`.

## Plugin Architecture

Standard Wheels plugin. The main CFC (`Basecoat.cfc`) contains `init()` and all public methods. Wheels injects every public method into controller and view scopes. Call them as `#functionName()#` in views.

## File Structure

```
packages/basecoat/
├── CLAUDE.md              # This file (Claude Code reads first)
├── Basecoat.cfc           # Main package CFC — ALL helpers here
├── package.json           # Package manifest
├── index.cfm              # Package UI page (Wheels debug panel)
├── box.json               # CommandBox package metadata
└── .ai/
    └── ARCHITECTURE.md    # Full architecture doc (long-form context)
```

### Single CFC Requirement

All public helper functions must be methods in `Basecoat.cfc`. Do not create separate CFCs — Wheels won't inject them.

## Coding Conventions

- `<cffunction>` tag syntax for all public methods
- `<cfargument>` with `required`, `type`, and `default` on every parameter
- `<cfset var local = {}>` for local variables
- Function names: camelCase with `ui` prefix for components, `basecoat` prefix for infrastructure
- View helpers return strings
- Multi-line HTML via `<cfsavecontent variable="local.html">` blocks
- Double quotes for HTML attributes
- Generate unique IDs via `Replace(Left(CreateUUID(), 8), "-", "", "all")` when caller omits ID

### Naming Patterns

- `basecoat*` prefix: infrastructure (basecoatIncludes)
- `ui*` prefix: component open tags (uiButton, uiCard, uiDialog)
- `ui*End` suffix: closing tags for block components (uiCardEnd, uiDialogEnd)
- `ui*Header/Content/Footer/Body` + End: sub-section helpers
- `$ui*` prefix (private): internal utilities ($uiLucideIcon, $uiBuildId)

## Turbo/Hotwire Awareness

This plugin does NOT depend on wheels-hotwire, but is **aware** of Turbo patterns:
- `uiButton()` accepts `turboConfirm` and `turboMethod` args (outputs `data-turbo-confirm` / `data-turbo-method` attributes) — these are inert without Turbo present
- `uiButton()` accepts `close=true` for dialog dismiss (native `<dialog>` API, no Turbo needed)
- Components generate standard HTML that works inside `<turbo-frame>` elements without modification

## Basecoat Markup Reference

All `ui*` helpers MUST generate markup matching these patterns from basecoatui.com v0.3.x:

### Buttons
```html
<button class="btn">Primary</button>
<button class="btn-secondary">Secondary</button>
<button class="btn-destructive">Destructive</button>
<button class="btn-outline">Outline</button>
<button class="btn-ghost">Ghost</button>
<button class="btn-link">Link</button>
<button class="btn-sm">Small</button>
<button class="btn-lg-destructive">Large Destructive</button>
<button class="btn-icon-outline"><svg>...</svg></button>
<button class="btn-sm-icon-destructive"><svg>...</svg></button>
<a href="/path" class="btn-secondary">Link as button</a>
```

**Class construction:** Parts joined by hyphens in order: `btn` + size? + icon? + variant?
- Primary uses bare `btn` (no variant suffix)
- Default size (md) omits size prefix
- Examples: `btn`, `btn-outline`, `btn-sm`, `btn-sm-outline`, `btn-icon`, `btn-icon-outline`, `btn-lg-icon-destructive`

### Badges
```html
<span class="badge">Default</span>
<span class="badge-secondary">Secondary</span>
<span class="badge-destructive">Destructive</span>
<span class="badge-outline">Outline</span>
```

### Alerts
```html
<div class="alert" role="alert">
    <svg><!-- icon --></svg>
    <div>
        <h5>Title</h5>
        <div>Description</div>
    </div>
</div>
<div class="alert alert-destructive" role="alert">...</div>
```

### Cards
```html
<div class="card">
    <div class="card-header">
        <h3>Title</h3>
        <p>Description</p>
    </div>
    <div class="card-content"><!-- content --></div>
    <div class="card-footer"><!-- actions --></div>
</div>
```

### Dialogs (Modals)
Native `<dialog>` with `showModal()`:
```html
<button type="button" onclick="document.getElementById('dlg-id').showModal()" class="btn-outline">Open</button>

<dialog id="dlg-id" class="dialog w-full sm:max-w-[425px] max-h-[612px]"
        aria-labelledby="dlg-id-title" aria-describedby="dlg-id-desc"
        onclick="if (event.target === this) this.close()">
    <div>
        <header>
            <h2 id="dlg-id-title">Title</h2>
            <p id="dlg-id-desc">Description</p>
        </header>
        <section><!-- content --></section>
        <footer><!-- actions --></footer>
        <button type="button" aria-label="Close dialog" onclick="this.closest('dialog').close()">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"
                 fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
                 stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
        </button>
    </div>
</dialog>
```

### Form Fields
```html
<!-- Standard text input -->
<div class="grid gap-2">
    <label for="fld-id">Label</label>
    <input type="text" id="fld-id" name="model[field]" class="input" />
</div>

<!-- With description -->
<div class="grid gap-2">
    <label for="fld-id">Label</label>
    <input type="text" id="fld-id" name="model[field]" class="input" />
    <p class="text-sm text-muted-foreground">Description</p>
</div>

<!-- With error -->
<div class="grid gap-2">
    <label for="fld-id">Label</label>
    <input type="text" id="fld-id" name="model[field]"
           class="input border-destructive" aria-invalid="true"
           aria-describedby="fld-id-error" />
    <p id="fld-id-error" class="text-sm text-destructive">Error message</p>
</div>

<!-- Textarea -->
<textarea id="fld-id" name="model[field]" class="textarea" rows="4"></textarea>

<!-- Select -->
<select id="fld-id" name="model[field]" class="select">
    <option value="">Choose...</option>
    <option value="a">A</option>
</select>

<!-- Checkbox (label AFTER input) -->
<div class="flex items-center gap-2">
    <input type="checkbox" id="fld-id" name="model[field]" class="checkbox" />
    <label for="fld-id">Label</label>
</div>

<!-- Switch (label AFTER input) -->
<div class="flex items-center gap-2">
    <input type="checkbox" id="fld-id" name="model[field]" class="switch" role="switch" />
    <label for="fld-id">Label</label>
</div>
```

### Tables
```html
<div class="table-container">
    <table class="table">
        <thead><tr><th>Header</th></tr></thead>
        <tbody><tr><td>Cell</td></tr></tbody>
    </table>
</div>
```

### Tabs (uses Basecoat JS)
```html
<div class="tabs" data-default="tab1">
    <div class="tabs-list">
        <button class="tabs-trigger" data-value="tab1">Tab 1</button>
        <button class="tabs-trigger" data-value="tab2">Tab 2</button>
    </div>
    <div class="tabs-content" data-value="tab1">Content 1</div>
    <div class="tabs-content" data-value="tab2">Content 2</div>
</div>
```

### Progress
```html
<div class="progress"><div class="progress-indicator" style="width: 60%"></div></div>
```

### Skeleton
```html
<div class="skeleton h-4 w-[250px]"></div>
```

### Spinner
```html
<div class="spinner"></div>
```

### Tooltip
```html
<span class="tooltip" data-tip="Tooltip text"><button class="btn">Hover</button></span>
```

### Separator
```html
<hr class="separator" />
```

## Implementation Order

### Phase 1: Infrastructure + Simple Components
1. `init()` — version, metadata
2. `basecoatIncludes()` — Basecoat CSS + Alpine.js script tags
3. `uiButton()` — **reference implementation** (already provided in seed)
4. `uiBadge()` — simple single-element (already provided in seed)
5. `uiIcon()` — public wrapper around `$uiLucideIcon()`
6. `uiSpinner()`, `uiSkeleton()`, `uiProgress()` — simple single-element helpers
7. `uiSeparator()` — trivial `<hr>`
8. `uiTooltip()` / `uiTooltipEnd()`

### Phase 2: Block Components
9. `uiAlert()` — self-closing block (title + description, no End needed)
10. `uiCard()` / `uiCardHeader()` / `uiCardContent()` / `uiCardFooter()` / `uiCardContentEnd()` / `uiCardFooterEnd()` / `uiCardEnd()`
11. `uiDialog()` / `uiDialogFooter()` / `uiDialogEnd()`

### Phase 3: Form Components
12. `uiField()` — the big one: label + input + description + error, with type switching (text, email, textarea, select, checkbox, switch, etc.)

### Phase 4: Complex Components
13. `uiTable()` / `uiTableHeader()` / `uiTableBody()` / `uiTableRow()` / `uiTableHead()` / `uiTableCell()` + all End variants
14. `uiTabs()` / `uiTabList()` / `uiTabTrigger()` / `uiTabContent()` + End variants
15. `uiDropdown()` / `uiDropdownItem()` / `uiDropdownSeparator()` / `uiDropdownEnd()`
16. `uiPagination()`

### Phase 5: Layout Components
17. `uiSidebar()` family
18. `uiBreadcrumb()` family

## Icon System

`$uiLucideIcon(name, size, strokeWidth)` is a private method that returns SVG strings for Lucide icons. The seed includes ~12 common icons. Claude Code should extend the icon map as components need them. Each icon is a struct entry mapping name → SVG inner paths.

`uiIcon()` is the public wrapper:
```cfml
#uiIcon(name="trash", size=16)#
#uiIcon(name="plus", size=20, class="text-muted-foreground")#
```

## Testing

Test helpers by verifying output strings. Focus on:
- Basecoat class construction (especially compound button classes: `btn-sm-icon-destructive`)
- ARIA attributes on dialogs (labelledby, describedby) and form fields (invalid, describedby)
- Unique ID generation when IDs are omitted
- Error state rendering in `uiField()` (border-destructive class, error paragraph)
- Checkbox/switch layout (flex row, label after input)
- Standard vs. checkbox/switch field layout differences
