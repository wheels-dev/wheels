---
title: paginationLinks()
description: "Builds and returns a string containing links to pages based on a paginated query. Uses linkTo() internally to build the link, so you need to pass in a route nam"
sidebar:
  label: paginationLinks()
  order: 0
---

## Signature

`paginationLinks()` — returns `any`




## Description

Builds and returns a string containing links to pages based on a paginated query. Uses linkTo() internally to build the link, so you need to pass in a route name or a controller/action/key combination. All other linkTo() arguments can be supplied as well, in which case they are passed through directly to linkTo(). If you have paginated more than one query in the controller, you can use the handle argument to reference them. (Don't forget to pass in a handle to the findAll() function in your controller first.)

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `windowSize` | `numeric` | yes | `2` | The number of page links to show around the current page. |
| `alwaysShowAnchors` | `boolean` | yes | `true` | Whether or not links to the first and last page should always be displayed. |
| `anchorDivider` | `string` | yes | `...` | String to place next to the anchors on either side of the list. |
| `linkToCurrentPage` | `boolean` | yes | `false` | Whether or not the current page should be linked to. |
| `prepend` | `string` | yes | — | String or HTML to be prepended before result. |
| `append` | `string` | yes | — | String or HTML to be appended after result. |
| `prependToPage` | `string` | yes | — | String or HTML to be prepended before each page number. |
| `prependOnFirst` | `boolean` | yes | `true` | Whether or not to prepend the prependToPage string on the first page in the list. |
| `prependOnAnchor` | `boolean` | yes | `true` | Whether or not to prepend the prependToPage string on the anchors. |
| `appendToPage` | `string` | yes | — | String or HTML to be appended after each page number. |
| `appendOnLast` | `boolean` | yes | `true` | Whether or not to append the appendToPage string on the last page in the list. |
| `appendOnAnchor` | `boolean` | yes | `true` | Whether or not to append the appendToPage string on the anchors. |
| `classForCurrent` | `string` | yes | — | Class name for the current page number (if linkToCurrentPage is true, the class name will go on the a element. If not, a span element will be used). |
| `handle` | `string` | yes | `query` | The handle given to the query that the pagination links should be displayed for. |
| `name` | `string` | yes | `page` | The name of the param that holds the current page number. |
| `showSinglePage` | `boolean` | yes | `false` | Will show a single page when set to true. (The default behavior is to return an empty string when there is only one page in the pagination). |
| `pageNumberAsParam` | `boolean` | yes | `true` | Decides whether to link the page number as a param or as part of a route. (The default behavior is true). |

</div>

## Examples

<pre>&lt;!--- Example 1: List authors page by page, 25 at a time ---&gt;
&lt;!--- Controller code ---&gt;
&lt;cfparam name=&quot;params.page&quot; default=&quot;1&quot;&gt;
&lt;cfset allAuthors = model(&quot;author&quot;).findAll(page=params.page, perPage=25, order=&quot;lastName&quot;)&gt;

&lt;!--- View code ---&gt;
&lt;ul&gt;
    &lt;cfoutput query=&quot;allAuthors&quot;&gt;
        &lt;li&gt;##firstName## ##lastName##&lt;/li&gt;
    &lt;/cfoutput&gt;
&lt;/ul&gt;
&lt;cfoutput&gt;##paginationLinks(action=&quot;listAuthors&quot;)##&lt;/cfoutput&gt;

&lt;!--- Example 2: Using the same model call above, show all authors with a window size of 5 ---&gt;
&lt;!--- View code ---&gt;
&lt;cfoutput&gt;##paginationLinks(action=&quot;listAuthors&quot;, windowSize=5)##&lt;/cfoutput&gt;

&lt;!--- Example 3: If more than one paginated query is being run, then you need to reference the correct `handle` in the view ---&gt;
&lt;!--- Controller code ---&gt;
&lt;cfset allAuthors = model(&quot;author&quot;).findAll(handle=&quot;authQuery&quot;, page=5, order=&quot;id&quot;)&gt;

&lt;!--- View code ---&gt;
&lt;ul&gt;
    &lt;cfoutput&gt;##paginationLinks(action=&quot;listAuthors&quot;, handle=&quot;authQuery&quot;, prependToLink=&quot;&lt;li&gt;&quot;, appendToLink=&quot;&lt;/li&gt;&quot;)##&lt;/cfoutput&gt;
&lt;/ul&gt;

&lt;!--- Example 4: Call to `paginationLinks` using routes ---&gt;
&lt;!--- Route setup in config/routes.cfm ---&gt;
&lt;cfset addRoute(name=&quot;paginatedCommentListing&quot;, pattern=&quot;blog/[year]/[month]/[day]/[page]&quot;, controller=&quot;theBlog&quot;, action=&quot;stats&quot;)&gt;
&lt;cfset addRoute(name=&quot;commentListing&quot;, pattern=&quot;blog/[year]/[month]/[day]&quot;,  controller=&quot;theBlog&quot;, action=&quot;stats&quot;)&gt;

&lt;!--- Ccontroller code ---&gt;
&lt;cfparam name=&quot;params.page&quot; default=&quot;1&quot;&gt;
&lt;cfset comments = model(&quot;comment&quot;).findAll(page=params.page, order=&quot;createdAt&quot;)&gt;

&lt;!--- View code ---&gt;
&lt;ul&gt;
    &lt;cfoutput&gt;##paginationLinks(route=&quot;paginatedCommentListing&quot;, year=2009, month=&quot;feb&quot;, day=10)##&lt;/cfoutput&gt;
&lt;/ul&gt;</pre>
