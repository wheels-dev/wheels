---
title: columnNames()
description: "Returns a list of column names for the table mapped to this model. The list is ordered according to the columns’ ordinal positions in the database table. This i"
sidebar:
  label: columnNames()
  order: 0
---

## Signature

`columnNames()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a list of column names for the table mapped to this model. The list is ordered according to the columns’ ordinal positions in the database table. This is useful for dynamically generating queries, forms, or for inspecting the database structure associated with a model.




## Examples

<pre><code class='javascript'>1. Get all column names for a model
userModel = model("user");
columns = userModel.columnNames();

writeOutput(columns);
// Might output: "id,first_name,last_name,email,created_at,updated_at"

2. Use column names to dynamically select fields in a query
userModel = model("user");
queryColumns = userModel.columnNames();
q = "SELECT #queryColumns# FROM users WHERE active = 1";</code></pre>
