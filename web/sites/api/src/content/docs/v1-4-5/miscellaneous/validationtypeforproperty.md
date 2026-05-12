---
title: validationTypeForProperty()
description: "Returns the validation type for the property"
sidebar:
  label: validationTypeForProperty()
  order: 0
---

## Signature

`validationTypeForProperty()` — returns `any`




## Description

Returns the validation type for the property

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of column to retrieve data for. |

</div>

## Examples

<pre>validationTypeForProperty(property) &lt;!--- first name is a varchar(50) column ---&gt;
&lt;cfset employee = model(&quot;employee&quot;).new()&gt;
&lt;!--- would output &quot;string&quot; ---&gt;
&lt;cfoutput&gt;#employee.validationTypeForProperty(&quot;firstName&quot;)&gt;#&lt;/cfoutput&gt;</pre>
