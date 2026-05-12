---
title: validationTypeForProperty()
description: "Returns the type of validation that Wheels would apply for a given property. This is useful if you want to dynamically inspect a model's property type or apply"
sidebar:
  label: validationTypeForProperty()
  order: 0
---

## Signature

`validationTypeForProperty()` — returns `any`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns the type of validation that Wheels would apply for a given property. This is useful if you want to dynamically inspect a model's property type or apply logic based on the property's expected format.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of column to retrieve data for. |

</div>

## Examples

<pre><code class='javascript'>// Create a new employee object
employee = model(&quot;employee&quot;).new();

1. Assume 'firstName' is a varchar(50) column
employee.validationTypeForProperty(&quot;firstName&quot;) (This will output: &quot;string&quot;)

2. Assume 'hireDate' is a datetime column
employee.validationTypeForProperty(&quot;hireDate&quot;) (This will output: &quot;date&quot;)

3. Assume 'salary' is a numeric column
employee.validationTypeForProperty(&quot;salary&quot;) (This will output: &quot;numeric&quot;)
</code></pre>
