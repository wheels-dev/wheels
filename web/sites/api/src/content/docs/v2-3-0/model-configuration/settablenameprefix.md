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

<pre><code class='javascript'>// In `models/User.cfc`, add a prefix to the default table name of `tbl`.
function config(){
	setTableNamePrefix(&quot;tbl&quot;);
}</code></pre>
