---
title: renameTable()
description: "Renames a table"
sidebar:
  label: renameTable()
  order: 0
---

## Signature

`renameTable()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Renames a table
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `oldName` | `string` | yes | — | Name the old table |
| `newName` | `string` | yes | — | New name for the table |

</div>

## Examples

<pre><code class='javascript'>// 1. Rename a table from its old name to a new name
renameTable(oldName=&quot;blogPosts&quot;, newName=&quot;posts&quot;);

// 2. Rename a table as part of a migration up/down pair
component extends=&quot;wheels.Migrator&quot; {

    function up() {
        renameTable(oldName=&quot;members&quot;, newName=&quot;users&quot;);
    }

    function down() {
        renameTable(oldName=&quot;users&quot;, newName=&quot;members&quot;);
    }

}
</code></pre>
