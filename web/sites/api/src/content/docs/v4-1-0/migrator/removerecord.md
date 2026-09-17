---
title: removeRecord()
description: "Removes existing records from a table"
sidebar:
  label: removeRecord()
  order: 0
---

## Signature

`removeRecord()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Removes existing records from a table
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to remove the record from |
| `where` | `string` | no | — | The where clause, i.e id = 123. Raw SQL — callers must supply a predicate or all=true. |
| `all` | `boolean` | no | `false` | When true, an empty where deletes every row. Default false (fail-closed). |

</div>

## Examples

<pre><code class='javascript'>// 1. Remove all records from a table (use with caution)
removeRecord(table = &quot;sessions&quot;);

// 2. Remove a specific record by primary key
removeRecord(table = &quot;roles&quot;, where = &quot;id = 1&quot;);

// 3. Remove multiple records matching a condition
removeRecord(table = &quot;users&quot;, where = &quot;active = 0&quot;);

// 4. Use removeRecord in a migration's down() function to reverse an addRecord call
component extends=&quot;wheels.migrator.Migration&quot; {
    function up() {
        addRecord(
            table = &quot;settings&quot;,
            name = &quot;maintenanceMode&quot;,
            value = &quot;false&quot;
        );
    }
    function down() {
        removeRecord(table = &quot;settings&quot;, where = &quot;name = 'maintenanceMode'&quot;);
    }
}
</code></pre>
