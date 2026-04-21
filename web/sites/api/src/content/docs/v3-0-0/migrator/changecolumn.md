---
title: changeColumn()
description: "Changes the definition of an existing column in a database table. This function is used in migration CFCs to update column properties such as type, size, defaul"
sidebar:
  label: changeColumn()
  order: 0
---

## Signature

`changeColumn()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Changes the definition of an existing column in a database table. This function is used in migration CFCs to update column properties such as type, size, default value, nullability, precision, and scale.



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
| `allowNull` | `boolean` | no | — | Whether to allow NULL values |
| `limit` | `numeric` | no | — | Character or integer size limit for column |
| `precision` | `numeric` | no | — | (For decimal type) the maximum number of digits allow |
| `scale` | `numeric` | no | — | (For decimal type) the number of digits to the right of the decimal point |
| `addColumns` | `boolean` | no | `false` | if true, attempts to add columns and database will likely throw an error if column already exists |

</div>

## Examples

<pre><code class='javascript'>1. Change the type and limit of a column
changeColumn(table='members', columnName='status', columnType='string', limit=50);

2. Change a decimal column’s precision and scale
changeColumn(table='products', columnName='price', columnType='decimal', precision=10, scale=2);

3. Change a column to allow NULL and set a default value
changeColumn(table='users', columnName='nickname', columnType='string', limit=100, allowNull=true, default='Guest');

4. Move a column to a specific position in the table
changeColumn(table='orders', columnName='status', columnType='string', limit=20, afterColumn='orderDate');</code></pre>
