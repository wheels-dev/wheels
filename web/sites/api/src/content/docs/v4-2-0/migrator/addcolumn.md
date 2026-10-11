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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The Name of the table to add the column to |
| `columnType` | `string` | yes | — | The type of the new column |
| `columnName` | `string` | no | — | The name of the new column |
| `columnNames` | `string` | no | — | Modern alias for `columnName` (matches the plural form every TableDefinition column helper accepts). Pass one or the other — not both. |
| `afterColumn` | `string` | no | — | The name of the column which this column should be inserted after |
| `referenceName` | `string` | no | — | Name for new reference column, see documentation for references function, required if columnType is 'reference' |
| `default` | `any` | no | — | Default value for this column |
| `allowNull` | `boolean` | no | — | Whether to allow NULL values |
| `limit` | `numeric` | no | — | Character or integer size limit for column |
| `precision` | `numeric` | no | — | precision value for decimal columns, i.e. number of digits the column can hold |
| `scale` | `numeric` | no | — | scale value for decimal columns, i.e. number of digits that can be placed to the right of the decimal point (must be less than or equal to precision) |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a simple string column to an existing table
addColumn(table=&quot;members&quot;, columnType=&quot;string&quot;, columnName=&quot;status&quot;, limit=50);

// 2. Add a boolean column with a default value and no NULLs allowed
addColumn(
    table=&quot;members&quot;,
    columnType=&quot;boolean&quot;,
    columnName=&quot;isActive&quot;,
    default=1,
    allowNull=false
);

// 3. Add a decimal column with precision and scale (e.g. for a price field)
addColumn(
    table=&quot;products&quot;,
    columnType=&quot;decimal&quot;,
    columnName=&quot;price&quot;,
    precision=10,
    scale=2,
    default=0,
    allowNull=false
);
</code></pre>
