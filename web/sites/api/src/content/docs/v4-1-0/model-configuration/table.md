---
title: table()
description: "Use this method to tell Wheels what database table to connect to for this model."
sidebar:
  label: table()
  order: 0
---

## Signature

`table()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Use this method to tell Wheels what database table to connect to for this model.
You only need to use this method when your table naming does not follow the standard Wheels convention of a singular object name mapping to a plural table name.
To not use a table for your model at all, call <code>table(false)</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `any` | yes | — | Name of the table to map this model to. |

</div>

## Examples

<pre><code class='javascript'>// 1. Map the `User` model to a non-standard table name.
// In models/User.cfc
function config() {
	// Tell Wheels to use `tbl_USERS` instead of the default `users` table.
	table(&quot;tbl_USERS&quot;);
}

// 2. Map a model to a table with a legacy prefix.
// In models/Product.cfc
function config() {
	table(&quot;legacy_products&quot;);
}

// 3. Declare a model that has no backing database table at all.
// In models/ApiResponse.cfc
function config() {
	table(false);
}
</code></pre>
