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

<pre><code class='javascript'>// Example: create a users table
t = createTable(name='users'); 
	t.string(columnNames='firstname,lastname', default='', null=false, limit=50);
	t.string(columnNames='email', default='', null=false, limit=255); 
	t.string(columnNames='passwordHash', default='', null=true, limit=500);
	t.string(columnNames='passwordResetToken,verificationToken', default='', null=true, limit=500);
	t.boolean(columnNames='passwordChangeRequired,verified', default=false); 
	t.datetime(columnNames='passwordResetTokenAt,passwordResetAt,loggedinAt', default='', null=true); 
	t.integer(columnNames='roleid', default=0, null=false, limit=3);
	t.timestamps();
t.create();

// Example: Create a table with a different Primary Key
t = createTable(name='tokens', id=false);
	t.primaryKey(name='id', null=false, type=&quot;string&quot;, limit=35 );
	t.datetime(columnNames=&quot;expiresAt&quot;, null=false);
	t.integer(columnNames='requests', default=0, null=false);
	t.timestamps();
t.create();

// Example: Create a Join Table with composite primary keys
t = createTable(name='userkintins', id=false); 
	t.primaryKey(name=&quot;userid&quot;, null=false, limit=11);
	t.primaryKey(name='profileid', type=&quot;string&quot;, limit=11 );  
t.create();
</code></pre>
