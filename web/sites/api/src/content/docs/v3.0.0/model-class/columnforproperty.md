---
title: columnForProperty()
description: "Returns the database column name that corresponds to a given model property. This is useful when your model property names differ from the actual database colum"
sidebar:
  label: columnForProperty()
  order: 0
---

## Signature

`columnForProperty()` — returns `any`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns the database column name that corresponds to a given model property. This is useful when your model property names differ from the actual database column names, or when you need to dynamically generate SQL queries or mappings.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to inspect. |

## Examples

<pre><code class='javascript'>1. Retrieve the column name for a property
user = model("user").columnForProperty("email");

writeOutput(user);  // Might output: "email_address"

2. Use in dynamic SQL queries
userModel = model("user");
column = userModel.columnForProperty("firstName");
query = "SELECT #column# FROM users WHERE id = 1";</code></pre>
