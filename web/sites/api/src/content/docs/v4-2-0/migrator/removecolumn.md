---
title: removeColumn()
description: "Removes a column from a database table"
sidebar:
  label: removeColumn()
  order: 0
---

## Signature

`removeColumn()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Removes a column from a database table
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table containing the column to remove |
| `columnName` | `string` | no | — | The column name to remove |
| `columnNames` | `string` | no | — | Modern alias for `columnName` (matches the plural form every TableDefinition column helper accepts). Pass one or the other — not both. |
| `referenceName` | `string` | no | — | optional reference name |

</div>

## Examples

<pre><code class='javascript'>// 1. Remove a column by specifying its name directly
removeColumn(table=&quot;members&quot;, columnName=&quot;status&quot;);

// 2. Remove a reference column using its reference name (removes the &lt;referenceName&gt;id column)
removeColumn(table=&quot;posts&quot;, referenceName=&quot;author&quot;);
// Removes the column named &quot;authorid&quot; from the posts table

// 3. Typical use inside a migration's down() method to reverse an addColumn()
function down() {
    removeColumn(table=&quot;products&quot;, columnName=&quot;discountPrice&quot;);
}
</code></pre>
