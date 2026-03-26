# Basecoat Plugin Architecture

See `CLAUDE.md` in the plugin root for the authoritative specification including markup reference, implementation phases, naming conventions, and testing guidance.

## Component Categories

- **Simple** (Phase 1): Button, Badge, Icon, Spinner, Skeleton, Progress, Separator, Tooltip
- **Block** (Phase 2): Alert, Card, Dialog
- **Form** (Phase 3): Field (text, email, textarea, select, checkbox, switch)
- **Complex** (Phase 4): Table, Tabs, Dropdown, Pagination
- **Layout** (Phase 5): Sidebar, Breadcrumb

## Design Principles

- All helpers return HTML strings for use in views via `#helperName()#`
- Markup matches basecoatui.com v0.3.x patterns exactly
- No JavaScript dependencies for core components (CSS-only where possible)
- Turbo-aware but Hotwire-independent
- Native `<dialog>` element for modals (no JS library)
