---
title: table()
description: "Use this method to tell CFWheels what database table to connect to for this model."
sidebar:
  label: table()
  order: 0
---

## Signature

`table()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Use this method to tell CFWheels what database table to connect to for this model.
You only need to use this method when your table naming does not follow the standard CFWheels convention of a singular object name mapping to a plural table name.
To not use a table for your model at all, call <code>table(false)</code>.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `any` | yes | — | Name of the table to map this model to. |

## Examples

<pre><code class='javascript'>// In models/User.cfc.
function config() {
	// Tell Wheels to use the `tbl_USERS` table in the database for the `user` model instead of the default (which would be `users`).
	table(&quot;tbl_USERS&quot;);
}</code></pre>
