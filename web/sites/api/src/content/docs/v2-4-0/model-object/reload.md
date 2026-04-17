---
title: reload()
description: "Reloads the property values of this object from the database."
sidebar:
  label: reload()
  order: 0
---

## Signature

`reload()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Reloads the property values of this object from the database.




## Examples

<pre><code class='javascript'>// Get an object, call a method on it that could potentially change values, and then reload the values from the database
employee = model(&quot;employee&quot;).findByKey(params.key);
employee.someCallThatChangesValuesInTheDatabase();
employee.reload();</code></pre>
