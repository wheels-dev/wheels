---
title: create()
description: "The create() method is used to create a database table based on the table definition that has been built using the migrator’s table definition functions (string"
sidebar:
  label: create()
  order: 0
---

## Signature

`create()` — returns `void`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

The create() method is used to create a database table based on the table definition that has been built using the migrator’s table definition functions (string(), integer(), boolean(), etc.). This method is only available within a migration CFC and finalizes the table creation in the database.




## Examples

<pre><code class='javascript'>t = table(name="employees");
t.string(columnNames="firstName", limit=50, allowNull=false);
t.string(columnNames="lastName", limit=50, allowNull=false);
t.integer(columnNames="age", allowNull=true);
t.boolean(columnNames="isActive", default="1");

// Create the table in the database
t.create();</code></pre>
