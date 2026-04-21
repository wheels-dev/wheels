---
title: propertyIsPresent()
description: "Returns true if the specified property exists on the model and is not a blank string."
sidebar:
  label: propertyIsPresent()
  order: 0
---

## Signature

`propertyIsPresent()` — returns `any`




## Description

Returns true if the specified property exists on the model and is not a blank string.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to inspect. |

</div>

## Examples

<pre>propertyIsPresent(property) &lt;!--- Get an object, set a value and then see if the property exists ---&gt;
&lt;cfset employee = model(&quot;employee&quot;).new()&gt;
&lt;cfset employee.firstName = &quot;dude&quot;&gt;
&lt;cfreturn employee.propertyIsPresent(&quot;firstName&quot;)&gt;&lt;!--- Returns true ---&gt;

&lt;cfset employee.firstName = &quot;&quot;&gt;
&lt;cfreturn employee.propertyIsPresent(&quot;firstName&quot;)&gt;&lt;!--- Returns false ---&gt;</pre>
