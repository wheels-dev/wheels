---
title: validationTypeForProperty()
description: "Returns the validation type for the property."
sidebar:
  label: validationTypeForProperty()
  order: 0
---

## Signature

`validationTypeForProperty()` — returns `any`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns the validation type for the property.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of column to retrieve data for. |

## Examples

<pre>// first name is a varchar(50) column
employee = model(&quot;employee&quot;).new();

&lt;!--- would output &quot;string&quot;---&gt;
#employee.validationTypeForProperty(&quot;firstName&quot;)#
</pre>
