---
title: addRecord()
description: "Adds a record to a table"
sidebar:
  label: addRecord()
  order: 0
---

## Signature

`addRecord()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Adds a record to a table
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to add the record to |

</div>

## Examples

<pre><code class='javascript'>addRecord(table='people',
		id = 1,
		title = &quot;Mr&quot;,
		firstname = &quot;Bruce&quot;,
		lastname = &quot;Wayne&quot;, 
		email = &quot;bruce@wayneenterprises.com&quot;,
		tel = &quot;555-67869099&quot;, 
);
</code></pre>
