---
title: addColumn()
description: "Adds a new column to an existing table."
sidebar:
  label: addColumn()
  order: 0
---

## Signature

`addColumn()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Adds a new column to an existing table.
 This function is only available inside a migration CFC and is part of the Wheels migrator API. Use it to evolve your database schema safely through versioned migrations.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The Name of the table to add the column to |
| `columnType` | `string` | yes | — | The type of the new column |
| `columnName` | `string` | yes | — | THe name of the new column |
| `afterColumn` | `string` | no | — | The name of the column which this column should be inserted after |
| `referenceName` | `string` | no | — | Name for new reference column, see documentation for references function, required if columnType is 'reference' |
| `default` | `string` | no | — | Default value for this column |
| `allowNull` | `boolean` | no | — | Whether to allow NULL values |
| `limit` | `numeric` | no | — | Character or integer size limit for column |
| `precision` | `numeric` | no | — | precision value for decimal columns, i.e. number of digits the column can hold |
| `scale` | `numeric` | no | — | scale value for decimal columns, i.e. number of digits that can be placed to the right of the decimal point (must be less than or equal to precision) |

## Examples

<pre><code class='javascript'>1. Add a simple string column
addColumn(
    table=&quot;members&quot;,
    columnType=&quot;string&quot;,
    columnName=&quot;status&quot;,
    limit=50
);

Adds a status column (string, max 50 chars) to the members table.

2. Add an integer column with default value
addColumn(
    table=&quot;orders&quot;,
    columnType=&quot;integer&quot;,
    columnName=&quot;priority&quot;,
    default=0
);

Adds a priority column with default value 0.

3. Add a boolean column that does not allow NULL
addColumn(
    table=&quot;users&quot;,
    columnType=&quot;boolean&quot;,
    columnName=&quot;isActive&quot;,
    allowNull=false,
    default=1
);

Adds an isActive column with default value true (1), disallowing NULL.

4. Add a decimal column with precision and scale
addColumn(
    table=&quot;products&quot;,
    columnType=&quot;decimal&quot;,
    columnName=&quot;price&quot;,
    precision=10,
    scale=2
);

Adds a price column with up to 10 digits total, including 2 decimal places.

5. Add a reference (foreign key) column
addColumn(
    table=&quot;orders&quot;,
    columnType=&quot;reference&quot;,
    columnName=&quot;userId&quot;,
    referenceName=&quot;users&quot;
);

Adds a userId column to orders and links it to the users table.</code></pre>
