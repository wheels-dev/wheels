---
title: reload()
description: "Refreshes the property values of a model object from the database. This is useful when an object’s values might have changed in the database due to other operat"
sidebar:
  label: reload()
  order: 0
---

## Signature

`reload()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Refreshes the property values of a model object from the database. This is useful when an object’s values might have changed in the database due to other operations or external processes. By calling reload(), you ensure that your object reflects the current state of the corresponding database record.




## Examples

<pre><code class='javascript'>1. Get an object, call a method on it that could potentially change values, and then reload the values from the database
employee = model(&quot;employee&quot;).findByKey(params.key);
employee.someCallThatChangesValuesInTheDatabase();
employee.reload();</code></pre>
