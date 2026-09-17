---
title: updateRecord()
description: "Updates an existing record in a table"
sidebar:
  label: updateRecord()
  order: 0
---

## Signature

`updateRecord()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Updates an existing record in a table
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name where the record is |
| `where` | `string` | no | — | The where clause, i.e admin = 1. Raw SQL — callers must supply a predicate or all=true. |
| `all` | `boolean` | no | `false` | When true, an empty where updates every row. Default false (fail-closed). |

</div>

## Examples

<pre><code class='javascript'>// 1. Update a single column for all rows in a table
updateRecord(
    table = &quot;settings&quot;,
    value = &quot;My Updated App&quot;
);

// 2. Update specific columns using a where clause to target matching rows
updateRecord(
    table = &quot;users&quot;,
    where = &quot;role = 'guest'&quot;,
    active = false
);

// 3. Update multiple columns during a migration's up() function
component extends=&quot;wheels.migrator.Migration&quot; {
    function up() {
        updateRecord(
            table = &quot;users&quot;,
            where = &quot;id = 1&quot;,
            firstName = &quot;Bruce&quot;,
            lastName = &quot;Wayne&quot;,
            email = &quot;bruce@wayneenterprises.com&quot;
        );
    }
    function down() {
        updateRecord(
            table = &quot;users&quot;,
            where = &quot;id = 1&quot;,
            firstName = &quot;Clark&quot;,
            lastName = &quot;Kent&quot;,
            email = &quot;clark@dailyplanet.com&quot;
        );
    }
}
</code></pre>
