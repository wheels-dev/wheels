# Pagination Helpers

Wheels provides composable pagination helpers that give you fine-grained control over pagination UI. Unlike `paginationLinks()` which generates a complete pagination block, these helpers let you build custom layouts by combining individual components.

All helpers read from the same pagination metadata set by `findAll(page=...)` or `setPagination()`.

## Quick Start

```cfm
<!--- Controller --->
<cfscript>
    users = model("User").findAll(page=params.page, perPage=25, order="lastName");
</cfscript>

<!--- View --->
#paginationNav()#
```

This renders a complete `<nav>` element with first/previous/page numbers/next/last links.

## Individual Helpers

### paginationInfo

Displays a text summary of the current pagination state.

```cfm
#paginationInfo()#
<!--- Output: "Showing 26-50 of 1,000 records" --->

#paginationInfo(format="Page [currentPage] of [totalPages]")#
<!--- Output: "Page 2 of 40" --->
```

Available tokens: `[startRow]`, `[endRow]`, `[totalRecords]`, `[currentPage]`, `[totalPages]`.

### previousPageLink / nextPageLink

```cfm
#previousPageLink()#  <!--- "Previous" link or disabled span --->
#nextPageLink()#      <!--- "Next" link or disabled span --->

<!--- Custom text --->
#previousPageLink(text="&laquo;")#
#nextPageLink(text="&raquo;")#

<!--- Hide when disabled instead of showing span --->
#previousPageLink(showDisabled=false)#
```

### firstPageLink / lastPageLink

```cfm
#firstPageLink()#  <!--- "First" link or disabled span --->
#lastPageLink()#   <!--- "Last" link or disabled span --->
```

### pageNumberLinks

Renders a windowed set of page number links around the current page.

```cfm
#pageNumberLinks()#
<!--- Output: 1 2 <span class="current">3</span> 4 5 --->

<!--- Larger window --->
#pageNumberLinks(windowSize=5)#

<!--- With list markup --->
#pageNumberLinks(prependToPage="<li>", appendToPage="</li>")#
```

### paginationNav

Composes all helpers into a semantic `<nav>` element.

```cfm
<!--- Full navigation --->
#paginationNav()#

<!--- Without first/last links --->
#paginationNav(showFirst=false, showLast=false)#

<!--- With info text --->
#paginationNav(showInfo=true)#

<!--- Custom CSS class --->
#paginationNav(navClass="my-pagination")#
```

## Building a Custom Pagination UI

The real power comes from combining helpers individually:

```cfm
<nav class="pagination" aria-label="Pagination">
    <div class="pagination-info">
        #paginationInfo()#
    </div>
    <ul class="pagination-links">
        <li>#previousPageLink(text="&laquo; Prev", disabledClass="text-muted")#</li>
        #pageNumberLinks(
            prependToPage="<li>",
            appendToPage="</li>",
            classForCurrent="active"
        )#
        <li>#nextPageLink(text="Next &raquo;", disabledClass="text-muted")#</li>
    </ul>
</nav>
```

## Bootstrap 5 Example

```cfm
<nav aria-label="Page navigation">
    <ul class="pagination">
        <li class="page-item">#previousPageLink(text="&laquo;", class="page-link", disabledClass="page-link")#</li>
        #pageNumberLinks(
            prependToPage="<li class='page-item'>",
            appendToPage="</li>",
            class="page-link",
            classForCurrent="page-link active"
        )#
        <li class="page-item">#nextPageLink(text="&raquo;", class="page-link", disabledClass="page-link")#</li>
    </ul>
</nav>
```

## Common Parameters

All helpers support these parameters:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `handle` | `"query"` | Handle for the paginated query |
| `encode` | `true` | HTML-encode output |

Link helpers (`previousPageLink`, `nextPageLink`, `firstPageLink`, `lastPageLink`) also support:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `text` | Varies | Link text |
| `name` | `"page"` | Query parameter name |
| `class` | `""` | CSS class for the link |
| `disabledClass` | `"disabled"` | CSS class for disabled state |
| `showDisabled` | `true` | Show disabled span or return empty string |
| `pageNumberAsParam` | `true` | Page as query param vs route segment |

## Multiple Paginated Queries

Use the `handle` parameter when paginating multiple queries:

```cfm
<!--- Controller --->
users = model("User").findAll(page=params.userPage, perPage=10, handle="users", order="name");
posts = model("Post").findAll(page=params.postPage, perPage=5, handle="posts", order="title");

<!--- View --->
<h2>Users</h2>
#paginationNav(handle="users")#

<h2>Posts</h2>
#paginationNav(handle="posts")#
```

## Changing Defaults

Override defaults in `config/settings.cfm`:

```cfm
<cfscript>
    // Change default text
    set(functionName="previousPageLink", text="&laquo; Prev");
    set(functionName="nextPageLink", text="Next &raquo;");

    // Change info format
    set(functionName="paginationInfo", format="Page [currentPage] of [totalPages]");

    // Larger page number window
    set(functionName="pageNumberLinks", windowSize=5);
</cfscript>
```
