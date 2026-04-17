---
title: columnForProperty()
description: "Returns the column name mapped for the named model property."
sidebar:
  label: columnForProperty()
  order: 0
---

## Signature

`columnForProperty()` — returns `any`




## Description

Returns the column name mapped for the named model property.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to inspect. |

## Examples

<pre>columnForProperty(property) &lt;!--- Get an object, set a value and then see if the property exists ---&gt;
&lt;cfset employee = model(&quot;employee&quot;).new()&gt;
&lt;cfset employee.columnForProperty(&quot;firstName&quot;)&gt;&lt;!--- returns column name, in this case &quot;firstname&quot; if the convention is used ---&gt;</pre>
