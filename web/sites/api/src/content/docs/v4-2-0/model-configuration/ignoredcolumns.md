---
title: ignoredColumns()
description: "Use this method to specify which columns cannot be used by the wheels ORM."
sidebar:
  label: ignoredColumns()
  order: 0
---

## Signature

`ignoredColumns()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Use this method to specify which columns cannot be used by the wheels ORM.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columns` | `array` | no | `[runtime expression]` | Array of columns names that will be ignored. |

</div>

## Examples

<pre><code class='javascript'>// 1. Ignore a single column in the model's config() method
// In app/models/User.cfc
component extends=&quot;Model&quot; {
	function config() {
		ignoredColumns(columns=[&quot;legacyField&quot;]);
	}
}

// 2. Ignore multiple columns so they are excluded from Wheels ORM property mapping
// In app/models/Product.cfc
component extends=&quot;Model&quot; {
	function config() {
		ignoredColumns(columns=[&quot;internalCode&quot;, &quot;deprecatedFlag&quot;, &quot;tempCache&quot;]);
	}
}
</code></pre>
