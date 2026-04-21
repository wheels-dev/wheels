---
title: changeColumn()
description: "changes a column definition"
sidebar:
  label: changeColumn()
  order: 0
---

## Signature

`changeColumn()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

changes a column definition
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The Name of the table where the column is |
| `columnName` | `string` | yes | — | THe name of the column |
| `columnType` | `string` | yes | — | The type of the column |
| `afterColumn` | `string` | no | — | The name of the column which this column should be inserted after |
| `referenceName` | `string` | no | — | Name for reference column, see documentation for references function, required if columnType is 'reference' |
| `default` | `string` | no | — | Default value for this column |
| `null` | `boolean` | no | — | Whether to allow NULL values |
| `limit` | `numeric` | no | — | Character or integer size limit for column |
| `precision` | `numeric` | no | — | (For decimal type) the maximum number of digits allow |
| `scale` | `numeric` | no | — | (For decimal type) the number of digits to the right of the decimal point |
| `addColumns` | `boolean` | no | `false` | if true, attempts to add columns and database will likely throw an error if column already exists |

</div>

## Examples

<pre><code class='javascript'>changeColumn(table='members', columnType='string', columnName='status', limit=50);
</code></pre>
