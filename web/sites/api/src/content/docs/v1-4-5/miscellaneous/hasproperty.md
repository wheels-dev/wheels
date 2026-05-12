---
title: hasProperty()
description: "Returns true if the specified property name exists on the model."
sidebar:
  label: hasProperty()
  order: 0
---

## Signature

`hasProperty()` — returns `any`




## Description

Returns true if the specified property name exists on the model.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to inspect. |

</div>

## Examples

<pre>hasProperty(property) &lt;!--- Get an object, set a value and then see if the property exists ---&gt;
&lt;cfset employee = model(&quot;employee&quot;).new()&gt;
&lt;cfset employee.firstName = &quot;dude&quot;&gt;
&lt;cfset employee.hasProperty(&quot;firstName&quot;)&gt;&lt;!--- returns true ---&gt;

&lt;!--- This is also a dynamic method that you could do ---&gt;
&lt;cfset employee.hasFirstName()&gt;</pre>
