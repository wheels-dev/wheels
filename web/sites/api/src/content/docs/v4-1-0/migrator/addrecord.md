---
title: addRecord()
description: "Adds a record to a table"
sidebar:
  label: addRecord()
  order: 0
---

## Signature

`addRecord()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Adds a record to a table
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to add the record to |

</div>

## Examples

<pre><code class='javascript'>// 1. Insert a simple seed record into a settings table
addRecord(
    table = &quot;settings&quot;,
    name = &quot;siteName&quot;,
    value = &quot;My Wheels App&quot;
);

// 2. Insert a record with multiple columns (extra keyword arguments become column/value pairs)
addRecord(
    table = &quot;people&quot;,
    id = 1,
    title = &quot;Mr&quot;,
    firstName = &quot;Bruce&quot;,
    lastName = &quot;Wayne&quot;,
    email = &quot;bruce@wayneenterprises.com&quot;,
    phone = &quot;555-678-9099&quot;
);

// 3. Seed an admin user role during a migration's up() function
component extends=&quot;wheels.migrator.Migration&quot; {
    function up() {
        addRecord(
            table = &quot;roles&quot;,
            id = 1,
            name = &quot;admin&quot;,
            active = true
        );
    }
    function down() {
        removeRecord(table = &quot;roles&quot;, where = &quot;id = 1&quot;);
    }
}
</code></pre>
