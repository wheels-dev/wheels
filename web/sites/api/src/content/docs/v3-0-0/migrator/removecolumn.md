---
title: removeColumn()
description: "Used to delete a column from a database table within a migration CFC. This is useful when you need to remove obsolete or incorrectly added columns during schema"
sidebar:
  label: removeColumn()
  order: 0
---

## Signature

`removeColumn()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Used to delete a column from a database table within a migration CFC. This is useful when you need to remove obsolete or incorrectly added columns during schema evolution. Optionally, you can also remove a reference column by specifying its referenceName. Only available in a migration CFC.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table containing the column to remove |
| `columnName` | `string` | no | — | The column name to remove |
| `referenceName` | `string` | no | — | optional reference name |

</div>

## Examples

<pre><code class='javascript'>1. Remove a single column from a table
removeColumn(table=&quot;users&quot;, columnName=&quot;middleName&quot;);

2. Remove a foreign key reference column
removeColumn(table=&quot;orders&quot;, referenceName=&quot;customerId&quot;);

3. Remove multiple columns in separate calls
removeColumn(table=&quot;products&quot;, columnName=&quot;oldPrice&quot;);
removeColumn(table=&quot;products&quot;, columnName=&quot;discountRate&quot;);
</code></pre>
