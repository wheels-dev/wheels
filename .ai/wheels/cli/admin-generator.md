# Admin Generator

Generate a complete admin CRUD interface for an existing model. The generator introspects the model at runtime to produce type-aware views, a namespaced controller with CSRF protection, and scoped routes.

## Prerequisites

- The model must already exist and be loadable by the running Wheels application
- The Wheels application server must be running

## Usage

```bash
wheels generate admin User
wheels generate admin Product --force
wheels generate admin Post --noRoutes
```

**Alias**: `wheels g admin User`

## Arguments

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `name` | Yes | — | Model name (singular PascalCase, e.g., "User", "Product") |
| `--force` | No | false | Overwrite existing files |
| `--noRoutes` | No | false | Skip route injection into config/routes.cfm |

## What It Generates

For `wheels generate admin User`:

1. **Controller**: `app/controllers/admin/Users.cfc`
   - Full CRUD actions (index, show, new, create, edit, update, delete)
   - CSRF protection via `protectsFromForgery()`
   - Scoped under `admin` namespace

2. **Views**: `app/views/admin/users/`
   - `index.cfm` — List view with pagination
   - `show.cfm` — Detail view
   - `new.cfm` — New record form
   - `edit.cfm` — Edit record form
   - `_form.cfm` — Shared form partial (type-aware fields based on model introspection)

3. **Routes** (unless `--noRoutes`): Injects scoped routes into `config/routes.cfm`
   ```cfm
   .namespace(name="admin")
       .resources("users")
   .end()
   ```

## Model Introspection

The generator reads the model's properties and associations at runtime to produce type-appropriate form fields:
- String properties → text fields
- Text/long properties → textareas
- Boolean properties → checkboxes
- Date/datetime properties → date fields
- Numeric properties → number fields
- BelongsTo associations → select dropdowns
