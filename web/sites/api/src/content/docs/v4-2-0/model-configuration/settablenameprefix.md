---
title: setTableNamePrefix()
description: "Sets a prefix to prepend to the table name when this model runs SQL queries."
sidebar:
  label: setTableNamePrefix()
  order: 0
---

## Signature

`setTableNamePrefix()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Sets a prefix to prepend to the table name when this model runs SQL queries.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `prefix` | `string` | yes | — | A prefix to prepend to the table name. |

</div>

## Examples

<pre><code class='javascript'>// 1. In `models/User.cfc`, prepend `tbl` to the default table name so
//    Wheels queries the `tblusers` table instead of `users`.
function config() {
	setTableNamePrefix(&quot;tbl&quot;);
}

// 2. Use a schema-style prefix to namespace legacy tables shared across
//    multiple applications on the same database.
// models/Order.cfc
component extends=&quot;Model&quot; {
	function config() {
		setTableNamePrefix(&quot;legacy_&quot;);
		// Wheels will now query `legacy_orders` for this model.
	}
}
</code></pre>
