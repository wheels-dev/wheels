---
title: paginationInfo()
description: "Displays a text summary of the current pagination state, e.g. \"Showing 26-50 of 1,000 records\"."
sidebar:
  label: paginationInfo()
  order: 0
---

## Signature

`paginationInfo()` — returns `string`

**Available in:** `controller`
**Category:** Pagination Functions

## Description

Displays a text summary of the current pagination state, e.g. "Showing 26-50 of 1,000 records".
Uses token replacement in the format string: 


## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `handle` | `string` | no | `query` | The handle given to the query that the pagination info should be displayed for. |
| `format` | `string` | no | `Showing [startRow]-[endRow] of [totalRecords] records` | Format string with tokens: [startRow], [endRow], [totalRecords], [currentPage], [totalPages]. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>//--------------------------------------------------------------------
// Example 1: Basic usage — display the default summary text for a
// paginated query (e.g. &quot;Showing 26-50 of 1,000 records&quot;)

// Controller code
param name=&quot;params.page&quot; type=&quot;integer&quot; default=&quot;1&quot;;
posts = model(&quot;Post&quot;).findAll(page=params.page, perPage=25, order=&quot;createdAt DESC&quot;);

// View code
&lt;cfoutput&gt;
    #paginationInfo()#
&lt;/cfoutput&gt;
// -&gt; &quot;Showing 26-50 of 1,000 records&quot;


//--------------------------------------------------------------------
// Example 2: Custom format string using available tokens
// Tokens: [startRow], [endRow], [totalRecords], [currentPage], [totalPages]

// View code
&lt;cfoutput&gt;
    #paginationInfo(format=&quot;Page [currentPage] of [totalPages] ([totalRecords] total)&quot;)#
&lt;/cfoutput&gt;
// -&gt; &quot;Page 2 of 40 (1,000 total)&quot;


//--------------------------------------------------------------------
// Example 3: Multiple paginated queries on the same page using handles

// Controller code
param name=&quot;params.postPage&quot; type=&quot;integer&quot; default=&quot;1&quot;;
param name=&quot;params.commentPage&quot; type=&quot;integer&quot; default=&quot;1&quot;;
posts    = model(&quot;Post&quot;).findAll(handle=&quot;posts&quot;, page=params.postPage, perPage=10, order=&quot;createdAt DESC&quot;);
comments = model(&quot;Comment&quot;).findAll(handle=&quot;comments&quot;, page=params.commentPage, perPage=5, order=&quot;createdAt DESC&quot;);

// View code
&lt;cfoutput&gt;
    Posts: #paginationInfo(handle=&quot;posts&quot;)#
    Comments: #paginationInfo(handle=&quot;comments&quot;)#
&lt;/cfoutput&gt;
// -&gt; &quot;Posts: Showing 1-10 of 87 records&quot;
// -&gt; &quot;Comments: Showing 1-5 of 342 records&quot;
</code></pre>
