---
title: tableName()
description: "Returns the name of the database table that a model is mapped to. Wheels automatically determines the table name based on its naming convention, where a singula"
sidebar:
  label: tableName()
  order: 0
---

## Signature

`tableName()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns the name of the database table that a model is mapped to. Wheels automatically determines the table name based on its naming convention, where a singular model name maps to a plural table name (for example, a model named User maps to the users table). If the table has been explicitly overridden using the <code>table()</code> function in the model’s <code>config()</code>, then <code>tableName()</code> will return the custom mapping instead. This function is useful when you want to programmatically check or log the database table a model is connected to, especially in projects with mixed or legacy naming conventions.




## Examples

<pre><code class='javascript'>// Check what table the user model uses
whatAmIMappedTo = model(&quot;user&quot;).tableName();</code></pre>
