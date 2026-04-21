---
title: addIndex()
description: "Add database index on a table column"
sidebar:
  label: addIndex()
  order: 0
---

## Signature

`addIndex()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Add database index on a table column
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the index operation on |
| `columnNames` | `string` | no | — | One or more column names to index, comma separated |
| `unique` | `boolean` | no | `false` | If true will create a unique index constraint |
| `indexName` | `string` | no | `[runtime expression]` | The name of the index to add: Defaults to table name + underscore + first column name |

</div>

## Examples

<pre><code class='javascript'>addIndex(table='members', columnNames='username', unique=true);
</code></pre>
