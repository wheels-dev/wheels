---
title: pagination()
description: "Returns a struct with information about the specified paginated query."
sidebar:
  label: pagination()
  order: 0
---

## Signature

`pagination()` — returns `struct`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Pagination Functions

## Description

Returns a struct with information about the specified paginated query.
The keys that will be included in the struct are <code>currentPage</code>, <code>totalPages</code> and <code>totalRecords</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `handle` | `string` | no | `query` | The handle given to the query to return pagination information for. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get pagination info for the default query handle
authors = model(&quot;Author&quot;).findAll(page=1, perPage=25, order=&quot;lastName&quot;);
info = pagination();
// info.currentPage  -&gt; 1
// info.totalPages   -&gt; 4
// info.totalRecords -&gt; 98

// 2. Get pagination info using a named handle (when running multiple paginated queries)
articles = model(&quot;Article&quot;).findAll(page=2, perPage=10, order=&quot;publishedAt DESC&quot;, handle=&quot;articles&quot;);
articleInfo = pagination(&quot;articles&quot;);
writeOutput(&quot;Page &quot; &amp; articleInfo.currentPage &amp; &quot; of &quot; &amp; articleInfo.totalPages);

// 3. Use pagination info to build a simple summary string
products = model(&quot;Product&quot;).findAll(page=params.page, perPage=20, order=&quot;name&quot;, handle=&quot;products&quot;);
info = pagination(&quot;products&quot;);
writeOutput(&quot;Showing page &quot; &amp; info.currentPage &amp; &quot; of &quot; &amp; info.totalPages &amp; &quot; (&quot; &amp; info.totalRecords &amp; &quot; total products)&quot;);
</code></pre>
