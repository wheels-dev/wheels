---
title: createTable()
description: "Creates a table definition object to store table properties"
sidebar:
  label: createTable()
  order: 0
---

## Signature

`createTable()` — returns `TableDefinition`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Creates a table definition object to store table properties
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | The name of the table to create |
| `force` | `boolean` | no | `false` | whether to drop the table before creating it |
| `id` | `boolean` | no | `true` | Whether to create a default primarykey or not |
| `primaryKey` | `string` | no | `id` | Name of the primary key field to create |

</div>

## Examples

<pre><code class='javascript'>// 1. Create a users table with standard columns and timestamps
t = createTable(name=&quot;users&quot;);
	t.string(columnNames=&quot;firstName,lastName&quot;, default=&quot;&quot;, allowNull=false, limit=50);
	t.string(columnNames=&quot;email&quot;, default=&quot;&quot;, allowNull=false, limit=255);
	t.string(columnNames=&quot;passwordHash&quot;, default=&quot;&quot;, allowNull=true, limit=500);
	t.boolean(columnNames=&quot;verified&quot;, default=false);
	t.integer(columnNames=&quot;roleId&quot;, default=0, allowNull=false);
	t.timestamps();
t.create();

// 2. Create a table with a custom string primary key (disabling the auto integer id)
t = createTable(name=&quot;tokens&quot;, id=false);
	t.primaryKey(name=&quot;id&quot;, allowNull=false, type=&quot;string&quot;, limit=36);
	t.string(columnNames=&quot;userId&quot;, allowNull=false, limit=36);
	t.datetime(columnNames=&quot;expiresAt&quot;, allowNull=false);
	t.timestamps();
t.create();

// 3. Create a join table with composite primary keys and force=true to recreate if it already exists
t = createTable(name=&quot;userRoles&quot;, id=false, force=true);
	t.primaryKey(name=&quot;userId&quot;, allowNull=false, limit=11);
	t.primaryKey(name=&quot;roleId&quot;, allowNull=false, limit=11);
t.create();
</code></pre>
