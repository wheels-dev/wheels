---
title: renameColumn()
description: "Renames a table column"
sidebar:
  label: renameColumn()
  order: 0
---

## Signature

`renameColumn()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Renames a table column
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table containing the column to rename |
| `columnName` | `string` | yes | — | The column name to rename |
| `newColumnName` | `string` | yes | — | The new column name |

</div>

## Examples

<pre><code class='javascript'>// 1. Rename a column in the users table
renameColumn(table=&quot;users&quot;, columnName=&quot;userName&quot;, newColumnName=&quot;username&quot;);

// 2. Rename a column as part of a migration's up() and down() methods
component extends=&quot;wheels.migrator.Migration&quot; hint=&quot;Rename fullName to displayName in profiles&quot; {
    function up() {
        renameColumn(table=&quot;profiles&quot;, columnName=&quot;fullName&quot;, newColumnName=&quot;displayName&quot;);
    }

    function down() {
        renameColumn(table=&quot;profiles&quot;, columnName=&quot;displayName&quot;, newColumnName=&quot;fullName&quot;);
    }
}
</code></pre>
