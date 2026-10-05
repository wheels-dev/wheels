# Pagination View Helpers

Part of the Wheels application guide; start with `../CLAUDE.md`.

Requires a paginated query: `findAll(page=params.page, perPage=25)`. Recommended all-in-one helper: `paginationNav()`.

For a JSON API, return `pagination()`'s values instead of rendering navigation (see `.ai/api.md`).

```cfm
// All-in-one nav
#paginationNav()#
#paginationNav(showInfo=true, showFirst="never", showLast="never", navClass="my-pagination")#
#paginationNav(windowSize=3)#

// Declarative presets — Bootstrap 4/5 and Tailwind
#paginationNav(viewStyle="bootstrap5")#
#paginationNav(viewStyle="bootstrap4")#
#paginationNav(viewStyle="tailwind")#

// Manual composition (like-for-like swap for legacy paginationLinks)
#paginationNav(
    navClass="",
    prepend='<ul class="pagination">',
    append="</ul>",
    prependToPage='<li class="page-item">',
    appendToPage="</li>",
    class="page-link",
    classForCurrent="active",
    addActiveClassToPrependedParent=true
)#

// Individual helpers
#paginationInfo()#       #firstPageLink()#       #previousPageLink()#
#pageNumberLinks()#      #nextPageLink()#        #lastPageLink()#
```

`showFirst` / `showLast` / `showPrevious` / `showNext` accept `"auto"` (default), `"always"`, or `"never"`. Under `"auto"` the first/last anchors are hidden when the window already reaches the boundary; previous/next render disabled `<span>` at boundaries to preserve position. Booleans coerce (`true`→`"always"`, `false`→`"never"`).

`viewStyle` accepts `"plain"` (default), `"bootstrap5"`, `"bootstrap4"`, `"tailwind"`. Bootstrap presets emit `<li class="page-item active" aria-current="page"><span class="page-link">N</span></li>`. Non-plain presets ignore manual-composition args.

In development, `paginationNav()` throws `Wheels.PaginationNav.InvalidArgument` for unknown sub-helper args. `windowSize` is consumed by `paginationNav` itself (not forwarded). Accepted pass-through: `format, text, name, class, disabledClass, showDisabled, pageNumberAsParam, classForCurrent, linkToCurrentPage, prependToPage, appendToPage, addActiveClassToPrependedParent, route, controller, action, key, anchor, onlyPath, host, protocol, port, params`. Named route segment variables are auto-exempted from the check.

# Development Error Page

When `showErrorInformation` is on (the development default), the framework
error page includes a **Copy** button. One click copies a JSON payload
(exception type and message, suggested action, file + line, source snippet,
and stack frames tagged app vs framework) to the clipboard for pasting into
a coding agent.
