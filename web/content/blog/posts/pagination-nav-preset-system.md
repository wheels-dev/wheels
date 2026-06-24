---
title: 'Pagination That Isn''t a Pain: paginationNav and the Preset System'
slug: pagination-nav-preset-system
publishedAt: '2026-06-24T14:00:00.000Z'
updatedAt: '2026-06-19T15:10:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - pagination
  - views
  - helpers
categories: []
excerpt: >-
  A complete how-to on Wheels 4.0's paginationNav helper — the all-in-one nav,
  the bootstrap5/bootstrap4/tailwind preset system, the auto/always/never
  anchor tri-state, and the dev-time guardrails that catch typos before they
  ship.
coverImage: null
---

You have a list of 1,000 blog posts and a view that needs to show 25 of them at a time. The query part is one line — `findAll(page=params.page, perPage=25)` — and Wheels has handled it cleanly since forever. The *navigation* part is where the afternoon goes.

In the old world you'd reach for `paginationLinks()`, then discover it gives you bare anchors and you have to hand-wrap each one in `<li class="page-item">` to make Bootstrap happy. So you build a wad of `prependToPage`/`appendToPage` arguments, copy that wad into four views, get one of the class names wrong in the third one, and ship a pagination bar that's subtly broken on the archive page nobody looks at until a customer does.

Wheels 4.0 ships `paginationNav()` — one helper that emits the whole `<nav>` element, info text and boundary links and numbered window included — plus a preset system so "make it look like Bootstrap 5" is an argument, not a markup-assembly project. This post walks the all-in-one path first, then the presets, then the knobs (anchor visibility, window size), and finishes with the sharp edges that'll bite you if you don't know they're there.

## The one prerequisite: a paginated query

Every pagination helper reads the same thing — a pagination struct that lives in `request.wheels[handle]`, keyed by a *handle* string. A paginated `findAll()` populates it for you:

```cfm
// app/controllers/Posts.cfc
component extends="Controller" {
    function index() {
        posts = model("Post").findAll(
            page = params.page ?: 1,
            perPage = 25,
            order = "createdAt DESC"
        );
    }
}
```

That `findAll(page=, perPage=)` call is the whole setup. Its default handle is `"query"`, which is also the default handle on every pagination helper — so as long as you have one paginated query per request, the helpers find it with zero ceremony.

The view drops the nav in below the loop. Remember: `findAll()` returns a **query object**, not an array, so you loop it with `query=`, and you `cfparam` every variable the controller handed you:

```cfm
<!--- app/views/posts/index.cfm --->
<cfparam name="posts" default="">
<cfoutput>
    <cfloop query="posts">#posts.title#<br></cfloop>

    #paginationNav()#
</cfoutput>
```

That's it. `paginationNav()` reads `pagination("query")`, sees currentPage, totalPages, totalRecords, and renders a `<nav class="pagination">` containing the windowed page numbers and the boundary anchors. No arguments, no markup, no copy-paste.

If you ever forget the paginated query, you'll know immediately in development: `pagination("query")` throws `Wheels.QueryHandleNotFound` when no query with that handle exists. That error message is the framework telling you "you didn't call `findAll(page=, perPage=)` — or you used a custom handle and forgot to pass it through." Which brings us to the one case that needs a hint.

## Custom handles

If you paginate two queries in one request, give each a distinct handle and pass the matching `handle=` to its nav:

```cfm
<!--- controller --->
posts    = model("Post").findAll(page=params.postPage ?: 1, perPage=25, handle="posts");
comments = model("Comment").findAll(page=params.commentPage ?: 1, perPage=10, handle="comments");

<!--- view --->
#paginationNav(handle="posts")#
#paginationNav(handle="comments")#
```

The handle is the only thread connecting a query to its nav. Get it matching on both ends and everything else falls out.

## The preset system

Here's the part that turns an afternoon into a one-liner. `paginationNav()` takes a `viewStyle` argument with four accepted values: `plain` (the default), `bootstrap5`, `bootstrap4`, and `tailwind`. The non-plain presets emit canonical, framework-correct markup — the exact `<li>`/`<a>`/`<span>` structure each CSS framework expects — with no `Replace()` post-processing on your end.

### Bootstrap 5

```cfm
<cfoutput>#paginationNav(viewStyle="bootstrap5", showInfo=true)#</cfoutput>
```

On page 2 of 40 (windowSize default of 2, so the window spans pages 1–4), that emits:

```html
<nav aria-label="Pagination">Showing 26-50 of 1,000 records 
  <ul class="pagination">
    <li class="page-item"><a class="page-link" href="...?page=1">1</a></li>
    <li class="page-item active" aria-current="page"><span class="page-link">2</span></li>
    <li class="page-item"><a class="page-link" href="...?page=3">3</a></li>
    ...
  </ul>
</nav>
```

The current page is a non-clickable `<span class="page-link">` inside an `<li class="page-item active" aria-current="page">` — exactly the structure Bootstrap 5's docs prescribe, `aria-current` and all.

### Bootstrap 4

```cfm
<cfoutput>#paginationNav(viewStyle="bootstrap4")#</cfoutput>
```

Byte-for-byte identical to bootstrap5 **except** the active `<li>` omits `aria-current="page"` — matching Bootstrap 4's markup, which predates that convention. That's the only difference between the two presets, and it's there because the frameworks genuinely differ.

### Tailwind

Tailwind doesn't use `<ul>`/`<li>` pagination, so the tailwind preset emits a flat `<nav>` of anchors:

```cfm
<cfoutput>#paginationNav(viewStyle="tailwind")#</cfoutput>
```

```html
<nav aria-label="Pagination" class="pagination">
  <a class="pagination-link" href="...?page=1">1</a>
  <span class="pagination-current" aria-current="page">2</span>
  <a class="pagination-link" href="...?page=3">3</a>
</nav>
```

No list wrapper. Links get `class="pagination-link"`, the current page is a `<span class="pagination-current" aria-current="page">`, and at a boundary a disabled First/Previous/Next/Last renders as `<span class="pagination-disabled">First</span>` so the layout doesn't jump.

Here's the table you'll actually refer back to:

| `viewStyle` | Wrapper | Current page | Disabled boundary anchor |
|---|---|---|---|
| `plain` (default) | `<nav class="pagination">` | `<span class="current">N</span>` | `<span class="disabled">First</span>` |
| `bootstrap5` | `<nav><ul class="pagination">` | `<li class="page-item active" aria-current="page"><span class="page-link">N</span></li>` | `<li class="page-item disabled"><span class="page-link">…</span></li>` |
| `bootstrap4` | `<nav><ul class="pagination">` | same as bootstrap5 **without** `aria-current` | same as bootstrap5 |
| `tailwind` | `<nav class="pagination">` (no `<ul>`) | `<span class="pagination-current" aria-current="page">N</span>` | `<span class="pagination-disabled">…</span>` |

One thing the presets do that you need to internalize: **the preset markup wins.** When `viewStyle` is non-plain, the manual-composition arguments — `prependToPage`, `appendToPage`, `classForCurrent`, `class` — are ignored in favor of the canonical structure. You don't get to half-override a preset. If you need custom markup, you're in `plain` mode (covered below). If you want Bootstrap, you take Bootstrap's markup as-is. That's the whole point of the preset.

## Tuning what shows: the anchor tri-state

`paginationNav()` has four boundary anchors — First, Previous, Next, Last — each controlled by its own `show*` argument: `showFirst`, `showPrevious`, `showNext`, `showLast`. Each accepts three string values:

| Value | Meaning |
|---|---|
| `"auto"` (default) | First/Last appear only when the page-number window hasn't already reached that boundary. Previous/Next always render (disabled at the edge). |
| `"always"` | Force the anchor on. |
| `"never"` | Suppress the anchor entirely. |

The `auto` behavior is the smart default and worth understanding. With `windowSize=2`, page 2 renders a window of pages 1–4. Since page 1 is already *in* the window, the First anchor would be redundant — so under `auto`, **it doesn't appear.** Want it anyway?

```cfm
<cfoutput>
    <!--- force First/Last on regardless of where the window sits --->
    #paginationNav(showFirst="always", showLast="always", windowSize=3)#
</cfoutput>
```

Previous and Next behave differently from First and Last under `auto`: they *always* delegate to their sub-helper, which renders a disabled `<span class="disabled">` at the boundary instead of vanishing. That's deliberate — it keeps the bar from shifting horizontally as you page. If you genuinely want them gone at the edges, ask for `"never"`:

```cfm
<cfoutput>
    <!--- no Previous/Next indicator at all, even disabled --->
    #paginationNav(showPrevious="never", showNext="never")#
</cfoutput>
```

For backwards compatibility, the `show*` args also coerce booleans: `true` maps to `"always"`, `false` maps to `"never"`. So `showFirst=false` is the same as `showFirst="never"`.

```cfm
<cfoutput>
    <!--- boolean form: true == always, false == never --->
    #paginationNav(showFirst=false, showLast=false)#
</cfoutput>
```

Two more knobs round out the common cases:

- **`showInfo`** (default `false`) — prepends the "Showing 26-50 of 1,000 records" summary. It's opt-in; pass `showInfo=true` to get it.
- **`windowSize`** (default `2`) — how many page links to show on each side of the current page. The default of 2 yields ~5 links centered on the current page. Bump it for wider bars: `windowSize=4` gives ~9.
- **`showSinglePage`** (default `false`) — when there's only one page of results, `paginationNav()` returns an empty string. Pass `showSinglePage=true` if you want the nav rendered even for a single page.

## When you need full control: plain-mode manual composition

The presets cover the three frameworks most people reach for. When you need bespoke markup — a CSS system that isn't Bootstrap or Tailwind, or a legacy design you're matching — stay in `plain` mode and compose the markup yourself. This is the like-for-like replacement for the old `paginationLinks()` structure:

```cfm
<cfoutput>
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
</cfoutput>
```

The argument roles:

| Arg | Role |
|---|---|
| `prepend` / `append` | Wrap the *entire* link list. Your outer `<ul>…</ul>`. Not forwarded to sub-helpers — these are paginationNav's own. |
| `prependToPage` / `appendToPage` | Wrap each individual page anchor *and* the First/Prev/Next/Last anchors. Your `<li>…</li>`. |
| `class` | Class applied to each page link. |
| `classForCurrent` | Class for the current page (defaults to `current`). |
| `addActiveClassToPrependedParent` | Injects the literal class `active ` into the prepended parent's `class` attribute (the `<li>`) on the current page (a Bootstrap idiom) — note it always uses `active`, not the value of `classForCurrent`, and has no effect if `prependToPage` has no `class` attribute. |
| `anchorDivider` | String joining the sections (default: a single space). paginationNav-only. |

These manual-composition args are valid **only** with `viewStyle="plain"`. Mix them with a preset and the preset ignores them — see the rule above.

## A worked end-to-end example

Let's assemble the whole thing for a real posts index with a Bootstrap 5 layout, info text, and a slightly wider window.

The model — nothing pagination-specific, just a normal Wheels model:

```cfm
// app/models/Post.cfc
component extends="Model" {
    function config() {
        belongsTo(name="author");
        validatesPresenceOf(properties="title,body");
    }
}
```

The controller paginates with an explicit handle and order:

```cfm
// app/controllers/Posts.cfc
component extends="Controller" {
    function index() {
        posts = model("Post").findAll(
            page = params.page ?: 1,
            perPage = 25,
            order = "createdAt DESC",
            handle = "posts"
        );
    }

    // controller filters must be private so they aren't routable
    private function requireLogin() {
        // ...
    }
}
```

The view — cfparam, loop the query, render the nav:

```cfm
<!--- app/views/posts/index.cfm --->
<cfparam name="posts" default="">
<cfoutput>
<table class="table">
    <cfloop query="posts">
        <tr><td>#posts.title#</td><td>#posts.createdAt#</td></tr>
    </cfloop>
</table>

#paginationNav(
    handle = "posts",
    viewStyle = "bootstrap5",
    showInfo = true,
    windowSize = 4
)#
</cfoutput>
```

Four arguments, a fully-styled Bootstrap 5 pagination bar with a record-count summary, and the page links emitted as `?page=N` query params automatically. That's the entire feature.

### The individual helpers, if you want them

`paginationNav()` is a composition of six lower-level helpers, and you can call any of them directly when you need to lay out the pieces yourself — for instance a "Newer / Older" two-button bar:

```cfm
<cfoutput>
    #previousPageLink(text="&larr; Newer")#
    #paginationInfo(format="Page [currentPage] of [totalPages]")#
    #nextPageLink(text="Older &rarr;")#
</cfoutput>
```

The full set:

| Helper | Renders |
|---|---|
| `paginationInfo()` | Text summary. Tokens: `[startRow]`, `[endRow]`, `[totalRecords]`, `[currentPage]`, `[totalPages]`. Returns `"No records found"` when there are zero records. |
| `firstPageLink()` / `lastPageLink()` | Boundary anchor to page 1 / last page. |
| `previousPageLink()` / `nextPageLink()` | Boundary anchor to current−1 / current+1. |
| `pageNumberLinks()` | The windowed set of numbered links. |

The four boundary helpers share a signature: `text`, `class`, `disabledClass` (default `disabled`), and `showDisabled` (default `true`). At the boundary — page 1 for First/Previous, last page for Next/Last — they return a disabled `<span>` when `showDisabled=true`, or an empty string when `showDisabled=false`.

## Sharp edges

Pagination is one of those features that's 95% trivial and 5% "why is this view throwing." The 5% is concentrated here — and most of it is the framework deliberately catching mistakes early.

**The query is the contract.** Every helper reads `request.wheels[handle]`, populated by `findAll(page=, perPage=)` (or `setPagination()` for a hand-built query). Forget it and `pagination("query")` throws `Wheels.QueryHandleNotFound` in development. If you passed a custom `handle` to `findAll()`, pass the *same* handle to `paginationNav()` — both default to `"query"`, but they have to match.

**Typo'd argument names throw — in development.** Pass an argument that isn't recognized and `paginationNav()` throws `Wheels.PaginationNav.InvalidArgument`. This exists because of a real bug (issue #2717): someone wrote `prependToList="<ul>"` instead of `prepend=`, and the typo was *silently dropped* — the nav just rendered without the wrapper and nobody noticed. Now the typo is loud. The exact accepted pass-through allowlist is:

```
format, text, name, class, disabledClass, showDisabled, pageNumberAsParam,
classForCurrent, linkToCurrentPage, prependToPage, appendToPage,
addActiveClassToPrependedParent, route, controller, action, key, anchor,
onlyPath, host, protocol, port, params
```

Anything outside that list (and outside paginationNav's own arguments) trips the error. **But only in development** — the check is gated on `showErrorInformation`. In production, CFML's argument dispatch silently drops the unknown arg, same as before. So you catch typos at dev time and pay nothing in prod.

**Named-route variables are exempt.** If you point the nav at a named route that has segment variables, those variables aren't in the static allowlist — but they don't trip the error, because the route's declared variables are filtered out first:

```cfm
<!--- userId isn't in the allowlist, but it's a segment of the userTimeline route, so no throw --->
#paginationNav(route="userTimeline", userId=user.id)#
```

**Two different errors, two different exception types.** Don't conflate them when you write a try/catch:

- Unknown *argument name* (`prependToList=…`) → `Wheels.PaginationNav.InvalidArgument`
- Invalid *show mode value* (`showFirst="bogus"`) → `Wheels.InvalidArgument` (no `PaginationNav` prefix)
- Unknown *viewStyle* (`viewStyle="boostrap5"` — note the typo) → `Wheels.InvalidViewStyle`

And note: the invalid-mode check is *not* gated on `showErrorInformation`. A bad `show*` value throws even in production, and even on single-page result sets, because it's an unambiguous coding error.

**Presets override manual-composition args.** Said it above, repeating it because it's the most common "why isn't my override working." With `viewStyle=bootstrap5/bootstrap4/tailwind`, the arguments `prependToPage`, `appendToPage`, `classForCurrent`, and `class` are ignored. Use those only with `viewStyle="plain"` (the default).

**`prepend`/`append` are not sanitized; `prependToPage`/`appendToPage` are.** The reasoning is about trust boundaries. `prepend`/`append` wrap the whole list and are treated as developer-authored structural markup (`<ul class="pagination">`), so they pass through verbatim. `prependToPage`/`appendToPage` are per-page template extension points — the kind of thing a CMS or theme layer might expose — so they're scrubbed: `on*=` event handlers and `javascript:` URIs are stripped after HTML-entity decoding. If you're wiring those wrappers from anything resembling user input, that scrub is your friend; don't route untrusted markup through `prepend`/`append`, which skips it.

**Single page renders nothing by default.** With one page of results, `paginationNav()` returns `""`. That's usually what you want — no point showing a one-page navigation bar — but it surprises people testing with a small dataset. Pass `showSinglePage=true` to force it.

**Page links are query params by default.** `pageNumberAsParam` defaults to `true` on every helper, so links come out as `?page=N`. Set `pageNumberAsParam=false` to embed the page number into a route's named segment instead.

## The short version

For 90% of views, pagination in Wheels 4.0 is two lines: paginate the query, drop in the nav.

```cfm
<!--- controller --->
posts = model("Post").findAll(page=params.page ?: 1, perPage=25);

<!--- view --->
#paginationNav()#
```

Need it to match your CSS framework? Add `viewStyle="bootstrap5"` (or `bootstrap4`, or `tailwind`). Need a record count? Add `showInfo=true`. Need to control the boundary links? Reach for the `auto`/`always`/`never` tri-state. Need fully custom markup? Drop to `plain` mode and compose it. And when you fat-finger an argument name, the framework tells you at dev time instead of shipping a quietly-broken nav to the one archive page nobody looks at.
