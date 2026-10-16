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
| `columnName` | `string` | no | — | The name of the column |
| `columnNames` | `string` | no | — | Modern alias for `columnName` (matches the plural form every TableDefinition column helper accepts). Pass one or the other — not both. |
| `columnType` | `string` | yes | — | The type of the column |
| `afterColumn` | `string` | no | — | The name of the column which this column should be inserted after |
| `referenceName` | `string` | no | — | Name for reference column, see documentation for references function, required if columnType is 'reference' |
| `default` | `any` | no | — | Default value for this column |
| `allowNull` | `boolean` | no | — | Whether to allow NULL values |
| `limit` | `numeric` | no | — | Character or integer size limit for column |
| `precision` | `numeric` | no | — | (For decimal type) the maximum number of digits allow |
| `scale` | `numeric` | no | — | (For decimal type) the number of digits to the right of the decimal point |
| `addColumns` | `boolean` | no | `false` | if true, attempts to add columns and database will likely throw an error if column already exists |

</div>

## Examples

<pre><code class='javascript'>// 1. Change a string column's length limit
changeColumn(table=&quot;members&quot;, columnName=&quot;status&quot;, columnType=&quot;string&quot;, limit=50);

// 2. Change a column type and set a default value
changeColumn(table=&quot;orders&quot;, columnName=&quot;quantity&quot;, columnType=&quot;integer&quot;, default=1);

// 3. Change a decimal column with precision and scale
changeColumn(table=&quot;products&quot;, columnName=&quot;price&quot;, columnType=&quot;decimal&quot;, precision=10, scale=2, allowNull=false);

// 4. Change a text column and explicitly allow NULL values
changeColumn(table=&quot;articles&quot;, columnName=&quot;summary&quot;, columnType=&quot;text&quot;, allowNull=true);
</code></pre>
