---
title: changeTable()
description: "Creates a table definition object to store modifications to table properties"
sidebar:
  label: changeTable()
  order: 0
---

## Signature

`changeTable()` — returns `TableDefinition`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Creates a table definition object to store modifications to table properties
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the table to set change properties on |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a new string column to an existing table
t = changeTable(name=&quot;employees&quot;);
t.string(columnNames=&quot;fullName&quot;, default=&quot;&quot;, allowNull=true, limit=255);
t.change();

// 2. Modify multiple columns at once (change type and nullability)
t = changeTable(name=&quot;products&quot;);
t.integer(columnNames=&quot;stock&quot;, default=0, allowNull=false);
t.boolean(columnNames=&quot;active&quot;, default=true, allowNull=false);
t.change();

// 3. Add a new column using addColumns=true so the migration fails gracefully if the column already exists
t = changeTable(name=&quot;orders&quot;);
t.datetime(columnNames=&quot;shippedAt&quot;, allowNull=true);
t.change(addColumns=true);
</code></pre>
