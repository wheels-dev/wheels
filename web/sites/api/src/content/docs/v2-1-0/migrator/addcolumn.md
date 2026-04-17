---
title: addColumn()
description: "adds a column to existing table"
sidebar:
  label: addColumn()
  order: 0
---

## Signature

`addColumn()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

adds a column to existing table
Only available in a migration CFC



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The Name of the table to add the column to |
| `columnType` | `string` | yes | — | The type of the new column |
| `columnName` | `string` | yes | — | THe name of the new column |
| `afterColumn` | `string` | no | — | The name of the column which this column should be inserted after |
| `referenceName` | `string` | no | — | Name for new reference column, see documentation for references function, required if columnType is 'reference' |
| `default` | `string` | no | — | Default value for this column |
| `null` | `boolean` | no | — | Whether to allow NULL values |
| `limit` | `numeric` | no | — | Character or integer size limit for column |
| `precision` | `numeric` | no | — | precision value for decimal columns, i.e. number of digits the column can hold |
| `scale` | `numeric` | no | — | scale value for decimal columns, i.e. number of digits that can be placed to the right of the decimal point (must be less than or equal to precision) |

## Examples

<pre><code class='javascript'>addColumn(table='members', columnType='string', columnName='status', limit=50);
</code></pre>
