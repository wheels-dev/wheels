---
title: pagination()
description: "Returns a struct with information about the specificed paginated query."
sidebar:
  label: pagination()
  order: 0
---

## Signature

`pagination()` — returns `struct`

**Available in:** `controller`, `model`, `migrator`
**Category:** Pagination Functions

## Description

Returns a struct with information about the specificed paginated query.
The keys that will be included in the struct are <code>currentPage</code>, <code>totalPages</code> and <code>totalRecords</code>.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `handle` | `string` | no | `query` | The handle given to the query to return pagination information for. |

## Examples

<pre>allAuthors = model(&quot;author&quot;).findAll(page=1, perPage=25, order=&quot;lastName&quot;, handle=&quot;authorsData&quot;);
paginationData = pagination(&quot;authorsData&quot;);

#pagination().currentPage#
#pagination().totalPages#
#pagination().totalRecords#</pre>
