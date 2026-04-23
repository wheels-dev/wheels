# wheels-basecoat

A Wheels package that ships CFML view helpers for [Basecoat UI](https://basecoatui.com) — shadcn/ui-quality components rendered as plain HTML + Tailwind CSS classes. No React, no build step. Works with or without [wheels-hotwire](../hotwire/README.md).

## Requirements

- Wheels 3.0+
- Lucee 5+ or Adobe ColdFusion 2018+
- Basecoat CSS (served from your app — see **Serving Basecoat CSS** below)

## Installation

```bash
# Activate the package
cp -r packages/basecoat vendor/basecoat

# Restart or reload your app
wheels reload
```

All `ui*` helpers become available in views and controllers via the package mixin system.

## Configuration

Basecoat has no `set()`-style application settings. Configuration is passed to helpers directly — the only helper with knobs is `basecoatIncludes()`:

```cfml
#basecoatIncludes(
    alpine = true,
    alpineVersion = "3",
    basecoatCSSPath = "/plugins/basecoat/assets/basecoat/basecoat.min.css",
    turboAware = true
)#
```

| Argument | Default | Description |
|---|---|---|
| `alpine` | `true` | Include the Alpine.js CDN script (needed for dropdowns, dialogs with transitions, tabs). |
| `alpineVersion` | `"3"` | Alpine.js major version. |
| `basecoatCSSPath` | `"/plugins/basecoat/assets/basecoat/basecoat.min.css"` | Path to the Basecoat CSS file your app serves. |
| `turboAware` | `true` | Emit the `<meta name="turbo-cache-control" content="no-preview">` tag — safe default when paired with wheels-hotwire. |

### Serving Basecoat CSS

This package ships helpers, not CSS assets. Grab `basecoat.min.css` from the [Basecoat UI releases](https://basecoatui.com) and serve it from your app — for example under `public/assets/basecoat.min.css` — then point `basecoatCSSPath` at it.

## Usage

### 1. Include CSS + JS in your layout

```cfm
<!-- app/views/layout.cfm -->
<!DOCTYPE html>
<html>
<head>
    <title>My App</title>
    #basecoatIncludes(basecoatCSSPath="/assets/basecoat.min.css")#
</head>
<body>
    #includeContent()#
</body>
</html>
```

### 2. Render components in views

```cfm
<!-- Buttons -->
#uiButton(text="Save", variant="primary")#
#uiButton(text="Cancel", variant="outline", href="/users")#
#uiButton(text="Delete", variant="destructive", turboConfirm="Are you sure?")#

<!-- Badges -->
#uiBadge(text="Active", variant="default")#
#uiBadge(text="Archived", variant="secondary")#

<!-- Alert -->
#uiAlert(title="Heads up", description="Your trial expires in 3 days.", variant="default")#

<!-- Card (block component — remember uiCardEnd()) -->
#uiCard()#
    #uiCardHeader(title="Order ##1234", description="Placed 2 days ago")#
    #uiCardContent()#
        <p>Order details go here.</p>
    #uiCardContentEnd()#
    #uiCardFooter()#
        #uiButton(text="View", href="/orders/1234")#
    #uiCardFooterEnd()#
#uiCardEnd()#

<!-- Form field (handles label + input + error) -->
#uiField(label="Email", name="user[email]", type="email", required=true)#
#uiField(label="Bio", name="user[bio]", type="textarea", rows=4)#
#uiField(label="Role", name="user[role]", type="select", options="admin:Admin,user:User")#
```

### 3. Component reference

All helpers live on `Basecoat.cfc` and are injected into controllers and views.

| Category | Helpers |
|---|---|
| Includes | `basecoatIncludes` |
| Buttons & icons | `uiButton`, `uiBadge`, `uiIcon`, `uiSpinner`, `uiSkeleton`, `uiProgress`, `uiSeparator` |
| Tooltip | `uiTooltip` / `uiTooltipEnd` |
| Alert | `uiAlert` |
| Card | `uiCard` / `uiCardHeader` / `uiCardContent` / `uiCardContentEnd` / `uiCardFooter` / `uiCardFooterEnd` / `uiCardEnd` |
| Dialog | `uiDialog` / `uiDialogFooter` / `uiDialogEnd` |
| Forms | `uiField` (text, email, textarea, select, checkbox, switch, …) |
| Table | `uiTable` / `uiTableHeader` / `uiTableBody` / `uiTableRow` / `uiTableHead` / `uiTableCell` + matching `*End` helpers |
| Tabs | `uiTabs` / `uiTabList` / `uiTabTrigger` / `uiTabContent` + matching `*End` helpers |
| Dropdown | `uiDropdown` / `uiDropdownItem` / `uiDropdownSeparator` / `uiDropdownEnd` |
| Pagination | `uiPagination` |
| Layout | `uiBreadcrumb` / `uiBreadcrumbItem` / `uiBreadcrumbSeparator` / `uiBreadcrumbEnd`, `uiSidebar` / `uiSidebarSection` / `uiSidebarItem` + matching `*End` helpers |

### Turbo-awareness

Basecoat does not depend on wheels-hotwire, but its helpers are Turbo-friendly:

- `uiButton()` accepts `turboConfirm` and `turboMethod` — emitted as `data-turbo-confirm` / `data-turbo-method` attributes and ignored when Turbo is absent.
- `uiButton(close=true)` closes the enclosing `<dialog>` via the native `HTMLDialogElement.close()` API — no JS library required.
- All block components generate markup that renders correctly inside `<turbo-frame>` elements.

## Deactivating

```bash
rm -rf vendor/basecoat
wheels reload
```

## Reference

- `packages/basecoat/CLAUDE.md` — markup reference, naming conventions, component categories
- `packages/basecoat/.ai/ARCHITECTURE.md` — design principles, phased component inventory
- [Basecoat UI](https://basecoatui.com) — upstream CSS component library

## License

MIT
