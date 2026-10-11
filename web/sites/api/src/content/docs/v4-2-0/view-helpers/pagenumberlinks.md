---
title: pageNumberLinks()
description: "Creates a windowed set of page number links around the current page."
sidebar:
  label: pageNumberLinks()
  order: 0
---

## Signature

`pageNumberLinks()` — returns `string`

**Available in:** `controller`
**Category:** Pagination Functions

## Description

Creates a windowed set of page number links around the current page.
The current page is rendered as a span (not a link) unless <code>linkToCurrentPage</code> is true.


When non-plain, emits the canonical wrapper markup for that framework (e.g. <code><li class="page-item active"></code>)
and ignores <code>prependToPage</code> / <code>appendToPage</code> / <code>classForCurrent</code> / <code>class</code> in favor of the preset.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `windowSize` | `numeric` | no | `2` | The number of page links to show around the current page. |
| `handle` | `string` | no | `query` | The handle given to the query that the pagination should be displayed for. |
| `name` | `string` | no | `page` | The name of the param that holds the current page number. |
| `class` | `string` | no | — | CSS class for each page number link. |
| `classForCurrent` | `string` | no | `current` | CSS class for the current page span or link. |
| `linkToCurrentPage` | `boolean` | no | `false` | Whether to render the current page as a link. |
| `prependToPage` | `string` | no | — | String to prepend before each page number. |
| `appendToPage` | `string` | no | — | String to append after each page number. |
| `addActiveClassToPrependedParent` | `boolean` | no | `false` | Whether to inject `active ` into the prependToPage `class` attribute on the current page (Bootstrap idiom). Has no effect if `prependToPage` contains no `class` attribute. |
| `pageNumberAsParam` | `boolean` | no | `true` | Decides whether to link the page number as a param or as part of a route. |
| `viewStyle` | `string` | no | `plain` | CSS-framework preset for markup: "plain" (default), "bootstrap5", "bootstrap4", or "tailwind". |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>//--------------------------------------------------------------------
// Example 1: Basic page number links for a paginated query

// Controller code
param name=&quot;params.page&quot; type=&quot;integer&quot; default=&quot;1&quot;;
posts = model(&quot;Post&quot;).findAll(page=params.page, perPage=10, order=&quot;createdAt DESC&quot;);

// View code — renders links like: 1 2 [3] 4 5  (current page as a span)
&lt;cfoutput&gt;#pageNumberLinks()#&lt;/cfoutput&gt;


//--------------------------------------------------------------------
// Example 2: Widen the window around the current page and add CSS classes

// View code — shows 5 pages on each side of the current page,
// styling each link and the current-page span differently
&lt;cfoutput&gt;
    #pageNumberLinks(windowSize=5, class=&quot;page-link&quot;, classForCurrent=&quot;active&quot;)#
&lt;/cfoutput&gt;


//--------------------------------------------------------------------
// Example 3: Wrap each page number in a list item

// View code
&lt;ul&gt;
    &lt;cfoutput&gt;
        #pageNumberLinks(prependToPage=&quot;&lt;li&gt;&quot;, appendToPage=&quot;&lt;/li&gt;&quot;)#
    &lt;/cfoutput&gt;
&lt;/ul&gt;


//--------------------------------------------------------------------
// Example 4: Make the current page a link (useful for reloading)

// View code
&lt;cfoutput&gt;#pageNumberLinks(linkToCurrentPage=true)#&lt;/cfoutput&gt;


//--------------------------------------------------------------------
// Example 5: Multiple paginated queries — reference each by its handle

// Controller code
authors = model(&quot;Author&quot;).findAll(handle=&quot;authorQuery&quot;, page=params.page, perPage=20, order=&quot;lastName&quot;);
posts   = model(&quot;Post&quot;).findAll(handle=&quot;postQuery&quot;,   page=params.page, perPage=5,  order=&quot;createdAt&quot;);

// View code
&lt;cfoutput&gt;
    Authors: #pageNumberLinks(handle=&quot;authorQuery&quot;)#
    Posts:   #pageNumberLinks(handle=&quot;postQuery&quot;)#
&lt;/cfoutput&gt;
</code></pre>
