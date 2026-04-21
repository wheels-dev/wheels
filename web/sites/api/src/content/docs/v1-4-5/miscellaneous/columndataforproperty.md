---
title: columnDataForProperty()
description: "Returns a struct with data for the named property."
sidebar:
  label: columnDataForProperty()
  order: 0
---

## Signature

`columnDataForProperty()` — returns `any`




## Description

Returns a struct with data for the named property.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of column to retrieve data for. |

</div>

## Examples

<pre>columnDataForProperty(property) &lt;!--- Get an object, set a value and then see if the property exists ---&gt;
&lt;cfset employee = model(&quot;employee&quot;).new()&gt;
&lt;cfset employee.columnDataForProperty(&quot;firstName&quot;)&gt;&lt;!--- returns column struct ---&gt;</pre>
