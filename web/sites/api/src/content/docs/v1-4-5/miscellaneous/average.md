---
title: average()
description: "Calculates the average value for a given property. Uses the SQL function AVG. If no records can be found to perform the calculation on you can use the ifNull ar"
sidebar:
  label: average()
  order: 0
---

## Signature

`average()` — returns `any`




## Description

Calculates the average value for a given property. Uses the SQL function AVG. If no records can be found to perform the calculation on you can use the ifNull argument to decide what should be returned.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of the property to calculate the average for. |
| `where` | `string` | yes | — | See documentation for findAll. |
| `include` | `string` | yes | — | See documentation for findAll. |
| `distinct` | `boolean` | yes | `false` | When true, AVG will be performed only on each unique instance of a value, regardless of how many times the value occurs. |
| `parameterize` | `any` | yes | `true` | See documentation for findAll. |
| `ifNull` | `any` | yes | — | The value returned if no records are found. Common usage is to set this to 0 to make sure a numeric value is always returned instead of a blank string. |
| `includeSoftDeletes` | `boolean` | yes | `false` | See documentation for findAll. |
| `group` | `string` | yes | — | See documentation for findAll. |

## Examples

<pre>// Get the average salary for all employees
avgSalary = model(&quot;employee&quot;).average(&quot;salary&quot;);

// Get the average salary for employees in a given department
avgSalary = model(&quot;employee&quot;).average(property=&quot;salary&quot;, where=&quot;departmentId=##params.key##&quot;);

// Make sure a numeric value is always returned if no records are calculated
avgSalary = model(&quot;employee&quot;).average(property=&quot;salary&quot;, where=&quot;salary BETWEEN ##params.min## AND ##params.max##&quot;, ifNull=0);</pre>
