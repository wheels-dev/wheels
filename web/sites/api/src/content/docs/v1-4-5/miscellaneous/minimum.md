---
title: minimum()
description: "Calculates the minimum value for a given property. Uses the SQL function MIN. If no records can be found to perform the calculation on you can use the ifNull ar"
sidebar:
  label: minimum()
  order: 0
---

## Signature

`minimum()` — returns `any`




## Description

Calculates the minimum value for a given property. Uses the SQL function MIN. If no records can be found to perform the calculation on you can use the ifNull argument to decide what should be returned.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of the property to get the lowest value for (must be a property of a numeric data type). |
| `where` | `string` | yes | — | See documentation for findAll. |
| `include` | `string` | yes | — | See documentation for findAll. |
| `parameterize` | `any` | yes | `true` | See documentation for findAll. |
| `ifNull` | `any` | yes | — | See documentation for average. |
| `includeSoftDeletes` | `boolean` | yes | `false` | See documentation for findAll. |
| `group` | `string` | yes | — | See documentation for findAll. |

</div>

## Examples

<pre>// Get the amount of the lowest salary for all employees
lowestSalary = model(&quot;employee&quot;).minimum(&quot;salary&quot;);

// Get the amount of the lowest salary for employees in a given department
lowestSalary = model(&quot;employee&quot;).minimum(property=&quot;salary&quot;, where=&quot;departmentId=##params.key##&quot;);

// Make sure a numeric amount is always returned, even when there were no records analyzed by the query
lowestSalary = model(&quot;employee&quot;).minimum(property=&quot;salary&quot;, where=&quot;salary BETWEEN ##params.min## AND ##params.max##&quot;, ifNull=0);</pre>
