---
title: createTable()
description: "The createTable() function is used in migration CFCs to define a new database table. It returns a TableDefinition object, on which you can specify columns, prim"
sidebar:
  label: createTable()
  order: 0
---

## Signature

`createTable()` — returns `TableDefinition`

**Available in:** `migration`
**Category:** Migration Functions

## Description

The createTable() function is used in migration CFCs to define a new database table. It returns a TableDefinition object, on which you can specify columns, primary keys, timestamps, and other table properties. Once the table is defined, you call create() to actually create it in the database.



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

<pre><code class='javascript'>// Example: create a users table
t = createTable(name='users'); 
	t.string(columnNames='firstname,lastname', default='', allowNull=false, limit=50);
	t.string(columnNames='email', default='', allowNull=false, limit=255); 
	t.string(columnNames='passwordHash', default='', allowNull=true, limit=500);
	t.string(columnNames='passwordResetToken,verificationToken', default='', allowNull=true, limit=500);
	t.boolean(columnNames='passwordChangeRequired,verified', default=false); 
	t.datetime(columnNames='passwordResetTokenAt,passwordResetAt,loggedinAt', default='', allowNull=true); 
	t.integer(columnNames='roleid', default=0, allowNull=false, limit=3);
	t.timestamps();
t.create();

// Example: Create a table with a different Primary Key
t = createTable(name='tokens', id=false);
	t.primaryKey(name='id', allowNull=false, type=&quot;string&quot;, limit=35 );
	t.datetime(columnNames=&quot;expiresAt&quot;, allowNull=false);
	t.integer(columnNames='requests', default=0, allowNull=false);
	t.timestamps();
t.create();

// Example: Create a Join Table with composite primary keys
t = createTable(name='userkintins', id=false); 
	t.primaryKey(name=&quot;userid&quot;, allowNull=false, limit=11);
	t.primaryKey(name='profileid', type=&quot;string&quot;, limit=11 );  
t.create();
</code></pre>
