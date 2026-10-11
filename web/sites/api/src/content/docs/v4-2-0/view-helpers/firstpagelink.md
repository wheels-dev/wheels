---
title: firstPageLink()
description: "Creates a link to the first page, or a disabled span when already on the first page."
sidebar:
  label: firstPageLink()
  order: 0
---

## Signature

`firstPageLink()` — returns `string`

**Available in:** `controller`
**Category:** Pagination Functions

## Description

Creates a link to the first page, or a disabled span when already on the first page.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | no | `First` | The text for the link. |
| `handle` | `string` | no | `query` | The handle given to the query that the pagination should be displayed for. |
| `name` | `string` | no | `page` | The name of the param that holds the current page number. |
| `class` | `string` | no | — | CSS class for the link element. |
| `disabledClass` | `string` | no | `disabled` | CSS class for the disabled span element. |
| `showDisabled` | `boolean` | no | `true` | Whether to render a disabled span when already on the first page. |
| `pageNumberAsParam` | `boolean` | no | `true` | Decides whether to link the page number as a param or as part of a route. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>//--------------------------------------------------------------------
// Example 1: Basic usage — show a &quot;First&quot; link at the top of a
// paginated list; renders a disabled span when already on page 1

// Controller code
param name=&quot;params.page&quot; type=&quot;integer&quot; default=&quot;1&quot;;
posts = model(&quot;Post&quot;).findAll(page=params.page, perPage=10, order=&quot;createdAt DESC&quot;);

// View code
&lt;cfoutput&gt;
    #firstPageLink()#
    #previousPageLink()#
    #pageNumberLinks()#
    #nextPageLink()#
    #lastPageLink()#
&lt;/cfoutput&gt;


//--------------------------------------------------------------------
// Example 2: Custom link text and CSS classes

// View code
&lt;cfoutput&gt;
    #firstPageLink(
        text=&quot;&amp;laquo;&amp;laquo; First&quot;,
        class=&quot;page-link&quot;,
        disabledClass=&quot;page-link disabled&quot;
    )#
&lt;/cfoutput&gt;


//--------------------------------------------------------------------
// Example 3: Hide the disabled element entirely when on the first page

// View code
&lt;cfoutput&gt;
    #firstPageLink(showDisabled=false)#
&lt;/cfoutput&gt;


//--------------------------------------------------------------------
// Example 4: Use a named route so page numbers appear in the URL path
// instead of as a query-string param (e.g. /articles/page/3)

// Route setup in app/config/routes.cfm
mapper()
    .get(name=&quot;paginatedArticles&quot;, pattern=&quot;articles/page/[page]&quot;, to=&quot;articles##index&quot;)
    .get(name=&quot;articles&quot;, pattern=&quot;articles&quot;, to=&quot;articles##index&quot;)
.end();

// Controller code
param name=&quot;params.page&quot; type=&quot;integer&quot; default=&quot;1&quot;;
articles = model(&quot;Article&quot;).findAll(page=params.page, perPage=20, order=&quot;title&quot;);

// View code
&lt;cfoutput&gt;
    #firstPageLink(route=&quot;paginatedArticles&quot;, pageNumberAsParam=false)#
&lt;/cfoutput&gt;
</code></pre>
