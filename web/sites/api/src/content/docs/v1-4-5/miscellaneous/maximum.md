---
title: maximum()
description: "Calculates the maximum value for a given property. Uses the SQL function MAX. If no records can be found to perform the calculation on you can use the ifNull ar"
sidebar:
  label: maximum()
  order: 0
---

## Signature

`maximum()` — returns `any`




## Description

Calculates the maximum value for a given property. Uses the SQL function MAX. If no records can be found to perform the calculation on you can use the ifNull argument to decide what should be returned.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of the property to get the highest value for (must be a property of a numeric data type). |
| `where` | `string` | yes | — | See documentation for findAll. |
| `include` | `string` | yes | — | See documentation for findAll. |
| `parameterize` | `any` | yes | `true` | See documentation for findAll. |
| `ifNull` | `any` | yes | — | See documentation for average. |
| `includeSoftDeletes` | `boolean` | yes | `false` | See documentation for findAll. |
| `group` | `string` | yes | — | See documentation for findAll. |

</div>

## Examples

<pre>// Get the amount of the highest salary for all employees
highestSalary = model(&quot;employee&quot;).maximum(&quot;salary&quot;);

// Get the amount of the highest salary for employees in a given department
highestSalary = model(&quot;employee&quot;).maximum(property=&quot;salary&quot;, where=&quot;departmentId=##params.key##&quot;);

// Make sure a numeric value is always returned, even if no records are found to calculate the maximum for
highestSalary = model(&quot;employee&quot;).maximum(property=&quot;salary&quot;, where=&quot;salary &gt; ##params.minSalary##&quot;, ifNull=0);</pre>
