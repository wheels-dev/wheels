---
title: announce()
description: "Outputs a custom message during migration execution. This is useful for logging progress or providing context when multiple migration steps are running."
sidebar:
  label: announce()
  order: 0
---

## Signature

`announce()` — returns `any`

**Available in:** `migration`, `tabledefinition`


## Description

Outputs a custom message during migration execution. This is useful for logging progress or providing context when multiple migration steps are running.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `message` | `string` | yes | — |  |

</div>

## Examples

<pre><code class='javascript'>1. Announce a step in a migration
announce("Adding status column to members table...");
addColumn(
    table = "members",
    columnType = "string",
    columnName = "status",
    limit = 50
);

2. Announce progress in multiple steps
announce("Creating orders table...");
createTable("orders", function(table) {
    table.integer("id");
    table.string("description");
});

announce("Adding index on orders.description...");
addIndex(table="orders", columnNames="description");

3. Use for debugging migrations
announce("Starting migration at #Now()#");

// Migration logic here...

announce("Migration completed successfully.");</code></pre>
