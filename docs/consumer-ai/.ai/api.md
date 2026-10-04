# JSON APIs Quick Reference

Part of the Wheels application guide; start with `../CLAUDE.md`.

## Generate a resource

```bash
wheels generate api-resource Widget name:string price:decimal
```

This writes the `Widget` model, a create-table migration, `app/controllers/api/Widgets.cfc`, a model spec and a controller spec, and adds `.namespace("api").resources(name="widgets", except="new,edit")` to `config/routes.cfm`, so the endpoints live under `/api/widgets`.

## The controller pattern

The generated controller is the pattern to follow:

```cfm
// app/controllers/api/Widgets.cfc (abridged)
component extends="wheels.Controller" {  // not the app's Controller, so no CSRF/session filters
    function config() {
        provides("json");
        filters(through = "setJsonResponse");
    }
    function show() {
        local.widget = model("widget").findByKey(params.key);
        if (IsObject(local.widget)) {
            renderWith(data = {"widget" = local.widget});
        } else {
            renderWith(data = {"error" = "Record not found"}, status = 404);
        }
    }
    private function setJsonResponse() {
        params.format = "json";  // answer JSON whatever the Accept header says
    }
}
```

- `renderWith()` picks the format from the request. Without `params.format = "json"` (the generated filter) or an `Accept: application/json` header, it looks for an HTML view and throws `Wheels.ViewNotFound`.
- Quote the keys of the struct you render (`{"widget" = ...}`) so their case is the same on every engine.
- Set the status with `status=`: the generated actions use 201 for a create, 204 (with `data = {}`) for a delete, 400 for a missing body, 404 for an unknown key, and 422 with `"errors" = record.allErrors()` for a failed validation.
- A JSON request body (`Content-Type: application/json`, `{"widget": {...}}`) arrives as `params.widget`.

## Pagination

`findAll(page=, perPage=)` paginates; `pagination()` then returns `currentPage`, `totalPages` and `totalRecords` for that query (pass `handle=` when the query has one). Copy the values into a struct with quoted keys: rendered as is, the key case varies.

```cfm
function index() {
    local.widgets = model("widget").findAll(page = params.page ?: 1, perPage = 25, returnAs = "objects");
    local.p = pagination();
    renderWith(data = {
        "widgets" = local.widgets,
        "pagination" = {"page" = local.p.currentPage, "totalPages" = local.p.totalPages, "totalRecords" = local.p.totalRecords}
    });
}
```

## Timestamps are UTC

`createdAt` and `updatedAt` are written in UTC: the `timeStampMode` setting defaults to `"utc"` (the other values are `"local"` and `"epoch"`, set with `set(timeStampMode = "local")` in `config/settings.cfm`). The values come back without a zone, and rendering the date as is labels it with the server's UTC offset, so the time is off by that offset. Format timestamps yourself:

```cfm
// timeStampMode "utc" (the default): the stored value is UTC
"createdAt" = DateFormat(widget.createdAt, "yyyy-mm-dd") & "T" & TimeFormat(widget.createdAt, "HH:mm:ss") & "Z"
```
