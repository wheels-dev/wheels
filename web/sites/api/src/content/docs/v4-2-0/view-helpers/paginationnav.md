---
title: paginationNav()
description: "Creates a complete pagination navigation element wrapping individual pagination helpers."
sidebar:
  label: paginationNav()
  order: 0
---

## Signature

`paginationNav()` — returns `string`

**Available in:** `controller`
**Category:** Pagination Functions

## Description

Creates a complete pagination navigation element wrapping individual pagination helpers.
Outputs a <code><nav></code> element containing first/previous/page-numbers/next/last links and optional info text.
The <code>showFirst</code> / <code>showLast</code> / <code>showPrevious</code> / <code>showNext</code> args accept the
strings <code>"auto"</code>, <code>"always"</code>, or <code>"never"</code>. Booleans are normalized for
backwards compatibility: <code>true</code> maps to <code>"always"</code>, <code>false</code> maps to <code>"never"</code>.
Under <code>"auto"</code> the first/last anchors only render when the visible page-number
window does not already reach the boundary (matching legacy 3.x semantics).
Under <code>"auto"</code> the previous/next anchors always delegate to their sub-helper,
which renders a disabled <code><span class="disabled"></code> at the boundary by default —
use <code>"never"</code> to suppress the boundary indicator entirely.


When non-plain, the entire nav is rendered with the framework's canonical structure
(e.g. <code><nav><ul class="pagination"><li class="page-item active">...</code>), removing the need
for <code>Replace()</code> post-processing in app code. Passed through to <code>pageNumberLinks()</code>.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `handle` | `string` | no | `query` | The handle given to the query that the pagination should be displayed for. |
| `navClass` | `string` | no | `pagination` | CSS class for the wrapping nav element. |
| `showFirst` | `any` | no | `auto` | Anchor display mode for the first page link: "auto" (default), "always", "never", or boolean. |
| `showLast` | `any` | no | `auto` | Anchor display mode for the last page link: "auto" (default), "always", "never", or boolean. |
| `showPrevious` | `any` | no | `auto` | Anchor display mode for the previous page link: "auto" (default), "always", "never", or boolean. |
| `showNext` | `any` | no | `auto` | Anchor display mode for the next page link: "auto" (default), "always", "never", or boolean. |
| `showInfo` | `boolean` | no | `false` | Whether to show the pagination info text. |
| `showSinglePage` | `boolean` | no | `false` | Whether to show pagination when there is only one page. |
| `windowSize` | `numeric` | no | `2` | Number of page links shown around the current page in `pageNumberLinks` and used by the auto-mode predicates. |
| `viewStyle` | `string` | no | `plain` | CSS-framework preset for markup: "plain" (default), "bootstrap5", "bootstrap4", or "tailwind". |
| `prepend` | `string` | no | — | String or HTML to be prepended inside the `<nav>` before the link list (e.g. `<ul class="pagination">`). |
| `append` | `string` | no | — | String or HTML to be appended inside the `<nav>` after the link list (e.g. `</ul>`). |
| `prependToPage` | `string` | no | — | String or HTML to wrap before each anchor (first/previous/page numbers/next/last). Forwards to `pageNumberLinks` for the numbered links. |
| `appendToPage` | `string` | no | — | String or HTML to wrap after each anchor (first/previous/page numbers/next/last). Forwards to `pageNumberLinks` for the numbered links. |
| `addActiveClassToPrependedParent` | `boolean` | no | `false` | Whether to inject `active ` into the prependToPage `class` attribute on the current page (Bootstrap idiom — forwards to `pageNumberLinks`). Applies only to numbered-page anchors, not to first / previous / next / last (which are never "current" in the Bootstrap sense). Has no effect if `prependToPage` contains no `class` attribute. |
| `anchorDivider` | `string` | no | ` ` | Separator inserted between the first/previous/page-numbers/next/last sections. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>//--------------------------------------------------------------------
// Example 1: Basic usage — render a full pagination nav for a
// paginated query (first, previous, page numbers, next, last links)

// Controller code
param name=&quot;params.page&quot; type=&quot;integer&quot; default=&quot;1&quot;;
posts = model(&quot;Post&quot;).findAll(page=params.page, perPage=25, order=&quot;createdAt DESC&quot;);

// View code
&lt;cfoutput&gt;
    #paginationNav()#
&lt;/cfoutput&gt;
// -&gt; &lt;nav class=&quot;pagination&quot;&gt;&lt;a href=&quot;/posts?page=1&quot;&gt;1&lt;/a&gt; &lt;a href=&quot;/posts?page=2&quot;&gt;2&lt;/a&gt; ...&lt;/nav&gt;


//--------------------------------------------------------------------
// Example 2: Show pagination info text alongside the nav links,
// and use a custom CSS class on the wrapping nav element

// View code
&lt;cfoutput&gt;
    #paginationNav(showInfo=true, navClass=&quot;pagination-bar&quot;)#
&lt;/cfoutput&gt;
// -&gt; &lt;nav class=&quot;pagination-bar&quot;&gt;Showing 1-25 of 87 records &lt;a href=&quot;...&quot;&gt;1&lt;/a&gt; ...&lt;/nav&gt;


//--------------------------------------------------------------------
// Example 3: Minimal nav — page numbers only (no first/last links)

// View code
&lt;cfoutput&gt;
    #paginationNav(showFirst=false, showLast=false)#
&lt;/cfoutput&gt;


//--------------------------------------------------------------------
// Example 4: Multiple paginated queries on the same page using handles

// Controller code
param name=&quot;params.postPage&quot; type=&quot;integer&quot; default=&quot;1&quot;;
param name=&quot;params.commentPage&quot; type=&quot;integer&quot; default=&quot;1&quot;;
posts    = model(&quot;Post&quot;).findAll(handle=&quot;posts&quot;, page=params.postPage, perPage=10, order=&quot;createdAt DESC&quot;);
comments = model(&quot;Comment&quot;).findAll(handle=&quot;comments&quot;, page=params.commentPage, perPage=5, order=&quot;createdAt DESC&quot;);

// View code
&lt;cfoutput&gt;
    #paginationNav(handle=&quot;posts&quot;)#
    #paginationNav(handle=&quot;comments&quot;)#
&lt;/cfoutput&gt;


//--------------------------------------------------------------------
// Example 5: Show pagination even when there is only one page of results

// View code
&lt;cfoutput&gt;
    #paginationNav(showSinglePage=true)#
&lt;/cfoutput&gt;
</code></pre>
