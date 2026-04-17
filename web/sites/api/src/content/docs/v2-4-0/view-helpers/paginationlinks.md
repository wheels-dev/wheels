---
title: paginationLinks()
description: "Builds and returns a string containing links to pages based on a paginated query."
sidebar:
  label: paginationLinks()
  order: 0
---

## Signature

`paginationLinks()` — returns `string`

**Available in:** `controller`
**Category:** Link Functions

## Description

Builds and returns a string containing links to pages based on a paginated query.
Uses <code>linkTo()</code> internally to build the link, so you need to pass in a route name or a controller/action/key combination.
All other <code>linkTo()</code> arguments can be supplied as well, in which case they are passed through directly to <code>linkTo()</code>.
If you have paginated more than one query in the controller, you can use the handle argument to reference them. (Don't forget to pass in a handle to the <code>findAll()</code> function in your controller first.)



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `windowSize` | `numeric` | no | `2` | The number of page links to show around the current page. |
| `alwaysShowAnchors` | `boolean` | no | `true` | Whether or not links to the first and last page should always be displayed. |
| `anchorDivider` | `string` | no | ` ... ` | String to place next to the anchors on either side of the list. |
| `linkToCurrentPage` | `boolean` | no | `false` | Whether or not the current page should be linked to. |
| `prepend` | `string` | no | — | String or HTML to be prepended before result. |
| `append` | `string` | no | — | String or HTML to be appended after result. |
| `prependToPage` | `string` | no | — | String or HTML to be prepended before each page number. |
| `prependOnFirst` | `boolean` | no | `true` | Whether or not to prepend the prependToPage string on the first page in the list. |
| `prependOnAnchor` | `boolean` | no | `true` | Whether or not to prepend the prependToPage string on the anchors. |
| `appendToPage` | `string` | no | — | String or HTML to be appended after each page number. |
| `appendOnLast` | `boolean` | no | `true` | Whether or not to append the appendToPage string on the last page in the list. |
| `appendOnAnchor` | `boolean` | no | `true` | Whether or not to append the appendToPage string on the anchors. |
| `classForCurrent` | `string` | no | — | Class name for the current page number (if linkToCurrentPage is true, the class name will go on the a element. If not, a span element will be used). |
| `handle` | `string` | no | `query` | The handle given to the query that the pagination links should be displayed for. |
| `name` | `string` | no | `page` | The name of the param that holds the current page number. |
| `showSinglePage` | `boolean` | no | `false` | Will show a single page when set to true. (The default behavior is to return an empty string when there is only one page in the pagination). |
| `pageNumberAsParam` | `boolean` | no | `true` | Decides whether to link the page number as a param or as part of a route. (The default behavior is true). |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre><code class='javascript'>//--------------------------------------------------------------------
// Example 1: List authors page by page, 25 at a time

// Controller code
param name=&quot;params.page&quot; type=&quot;integer&quot; default=&quot;1&quot;;
authors = model(&quot;author&quot;).findAll(page=params.page, perPage=25, order=&quot;lastName&quot;);

// View code
&lt;ul&gt;
    &lt;cfoutput query=&quot;authors&quot;&gt;
        &lt;li&gt;#EncodeForHtml(firstName)# #EncodeForHtml(lastName)#&lt;/li&gt;
    &lt;/cfoutput&gt;
&lt;/ul&gt;

&lt;cfoutput&gt;#paginationLinks(route=&quot;authors&quot;)#&lt;/cfoutput&gt;


//--------------------------------------------------------------------
// Example 2: Using the same model call above, show all authors with a
// window size of 5

// View code
&lt;cfoutput&gt;#paginationLinks(route=&quot;authors&quot;, windowSize=5)#&lt;/cfoutput&gt;


//--------------------------------------------------------------------
// Example 3: If more than one paginated query is being run, then you
// need to reference the correct `handle` in the view

// Controller code
authors = model(&quot;author&quot;).findAll(handle=&quot;authQuery&quot;, page=5, order=&quot;id&quot;);

// View code
&lt;ul&gt;
    &lt;cfoutput&gt;
        #paginationLinks(
            route=&quot;authors&quot;,
            handle=&quot;authQuery&quot;,
            prependToLink=&quot;&lt;li&gt;&quot;,
            appendToLink=&quot;&lt;/li&gt;&quot;
        )#
    &lt;/cfoutput&gt;
&lt;/ul&gt;


//--------------------------------------------------------------------
// Example 4: Call to `paginationLinks` using routes

// Route setup in config/routes.cfm
mapper()
    .get(name=&quot;paginatedCommentListing&quot;, pattern=&quot;blog/[year]/[month]/[day]/[page]&quot;, to=&quot;blogs##stats&quot;)
    .get(name=&quot;commentListing&quot;, pattern=&quot;blog/[year]/[month]/[day]&quot;, to=&quot;blogs##stats&quot;)
.end();

// Controller code
param name=&quot;params.page&quot; type=&quot;integer&quot; default=&quot;1&quot;;
comments = model(&quot;comment&quot;).findAll(page=params.page, order=&quot;createdAt&quot;);

// View code
&lt;ul&gt;
    &lt;cfoutput&gt;
        #paginationLinks(
            route=&quot;paginatedCommentListing&quot;,
            year=2009,
            month=&quot;feb&quot;,
            day=10
        )#
    &lt;/cfoutput&gt;
&lt;/ul&gt;
</code></pre>
