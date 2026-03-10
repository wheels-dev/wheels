# Pagination View Helpers

Composable helpers for building custom pagination UIs. All read from pagination metadata set by `findAll(page=...)` or `setPagination()`.

## Helpers

### paginationInfo(handle, format, encode)
Text summary. Default format: `"Showing [startRow]-[endRow] of [totalRecords] records"`.
Tokens: `[startRow]`, `[endRow]`, `[totalRecords]`, `[currentPage]`, `[totalPages]`.
Returns `"No records found"` when totalRecords is 0.

### previousPageLink(text, handle, name, class, disabledClass, showDisabled, pageNumberAsParam, encode)
Link to previous page. Renders `<span class="disabled">` on first page (or empty string if `showDisabled=false`).

### nextPageLink(text, handle, name, class, disabledClass, showDisabled, pageNumberAsParam, encode)
Link to next page. Renders disabled span on last page.

### firstPageLink(text, handle, name, class, disabledClass, showDisabled, pageNumberAsParam, encode)
Link to first page. Disabled when already on page 1.

### lastPageLink(text, handle, name, class, disabledClass, showDisabled, pageNumberAsParam, encode)
Link to last page. Disabled when already on last page.

### pageNumberLinks(windowSize, handle, name, class, classForCurrent, linkToCurrentPage, prependToPage, appendToPage, pageNumberAsParam, encode)
Windowed page numbers. Current page renders as `<span class="current">` unless `linkToCurrentPage=true`.

### paginationNav(handle, navClass, showFirst, showLast, showPrevious, showNext, showInfo, showSinglePage, encode)
Complete `<nav class="pagination">` composing all above helpers. Returns empty string for single page unless `showSinglePage=true`.

## Defaults (config/settings.cfm)
```cfm
set(functionName="previousPageLink", text="&laquo; Prev");
set(functionName="nextPageLink", text="Next &raquo;");
set(functionName="paginationInfo", format="Page [currentPage] of [totalPages]");
set(functionName="pageNumberLinks", windowSize=5);
```

## Multiple Handles
```cfm
// Controller
users = model("User").findAll(page=params.userPage, perPage=10, handle="users", order="name");
// View
#paginationNav(handle="users")#
```

## Relationship to paginationLinks()
These helpers complement (not replace) the existing `paginationLinks()` monolithic helper. Use `paginationLinks()` for quick defaults; use these composable helpers when you need custom layouts.

## Implementation
- File: `vendor/wheels/view/pagination.cfc`
- Defaults: `vendor/wheels/events/init/functions.cfm`
- Tests: `tests/specs/view/PaginationHelpersSpec.cfc`
- All helpers use `$args()` for defaults, `pagination()` for metadata, and `linkTo()` for link generation.
