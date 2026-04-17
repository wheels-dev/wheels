---
title: reload()
description: "Reloads the property values of this object from the database."
sidebar:
  label: reload()
  order: 0
---

## Signature

`reload()` — returns `any`




## Description

Reloads the property values of this object from the database.


## Examples

<pre>reload() &lt;!--- Get an object, call a method on it that could potentially change values, and then reload the values from the database ---&gt;
&lt;cfset employee = model(&quot;employee&quot;).findByKey(params.key)&gt;
&lt;cfset employee.someCallThatChangesValuesInTheDatabase()&gt;
&lt;cfset employee.reload()&gt;</pre>
