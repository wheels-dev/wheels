---
title: minimum()
description: "Calculates the minimum value for a given property."
sidebar:
  label: minimum()
  order: 0
---

## Signature

`minimum()` — returns `any`

**Available in:** `model`
**Category:** Statistics Functions

## Description

Calculates the minimum value for a given property.
Uses the SQL function <code>MIN</code>.
If no records can be found to perform the calculation on you can use the <code>ifNull</code> argument to decide what should be returned.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of the property to get the lowest value for (must be a property of a numeric data type). |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. You do not need to specify the table name(s); CFWheels will do that for you. |
| `include` | `string` | no | — | Associations that should be included in the query using `INNER` or `LEFT OUTER` joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. `department,addresses,emails`). You can build more complex include strings by using parentheses when the association is set on an included model, like `album(artist(genre))`, for example. These complex `include` strings only work when `returnAs` is set to `query` though. |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `ifNull` | `any` | no | — | The value returned if no records are found. Common usage is to set this to `0` to make sure a numeric value is always returned instead of a blank string. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |
| `group` | `string` | no | — | Maps to the `GROUP BY` clause of the query. You do not need to specify the table name(s); CFWheels will do that for you. |

</div>

## Examples

<pre>// Get the amount of the lowest salary for all employees
lowestSalary = model(&quot;employee&quot;).minimum(&quot;salary&quot;);

// Get the amount of the lowest salary for employees in a given department
lowestSalary = model(&quot;employee&quot;).minimum(property=&quot;salary&quot;, where=&quot;departmentId=#params.key#&quot;);

// Make sure a numeric amount is always returned, even when there were no records analyzed by the query
lowestSalary = model(&quot;employee&quot;).minimum(property=&quot;salary&quot;, where=&quot;salary BETWEEN #params.min# AND #params.max#&quot;, ifNull=0);</pre>
