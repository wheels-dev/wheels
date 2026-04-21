---
title: pagination()
description: "Returns a struct with information about the specificed paginated query. The keys that will be included in the struct are currentPage, totalPages and totalRecord"
sidebar:
  label: pagination()
  order: 0
---

## Signature

`pagination()` — returns `any`




## Description

Returns a struct with information about the specificed paginated query. The keys that will be included in the struct are currentPage, totalPages and totalRecords.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `handle` | `string` | yes | `query` | The handle given to the query to return pagination information for. |

</div>

## Examples

<pre>allAuthors = model(&quot;author&quot;).findAll(page=1, perPage=25, order=&quot;lastName&quot;, handle=&quot;authorsData&quot;);
paginationData = pagination(&quot;authorsData&quot;);

#pagination().currentPage#
#pagination().totalPages#
#pagination().totalRecords#</pre>
