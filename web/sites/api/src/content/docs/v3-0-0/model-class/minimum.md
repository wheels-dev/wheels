---
title: minimum()
description: "Calculates the minimum value for a specified property in a model using SQL's MIN() function. This can be used to find the lowest value of a numeric property acr"
sidebar:
  label: minimum()
  order: 0
---

## Signature

`minimum()` — returns `any`

**Available in:** `model`
**Category:** Statistics Functions

## Description

Calculates the minimum value for a specified property in a model using SQL's MIN() function. This can be used to find the lowest value of a numeric property across all records or with conditions. You can also include associations, handle soft-deleted records, provide fallback values, and group results. If no records can be found to perform the calculation on you can use the <code>ifNull</code> argument to decide what should be returned.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of the property to get the lowest value for (must be a property of a numeric data type). |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. Nested queries not allowed. You do not need to specify the table name(s); Wheels will do that for you. |
| `include` | `string` | no | — | Associations that should be included in the query using `INNER` or `LEFT OUTER` joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. `department,addresses,emails`). You can build more complex include strings by using parentheses when the association is set on an included model, like `album(artist(genre))`, for example. These complex `include` strings only work when `returnAs` is set to `query` though. |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `ifNull` | `any` | no | — | The value returned if no records are found. Common usage is to set this to `0` to make sure a numeric value is always returned instead of a blank string. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |
| `group` | `string` | no | — | Maps to the `GROUP BY` clause of the query. You do not need to specify the table name(s); Wheels will do that for you. |

## Examples

<pre><code class='javascript'>1. Basic Minimum Value
// Get the lowest salary among all employees
lowestSalary = model(&quot;employee&quot;).minimum(&quot;salary&quot;);
writeOutput(&quot;Lowest Salary: &quot; &amp; lowestSalary);
// inline: writeOutput(model(&quot;employee&quot;).minimum(&quot;salary&quot;));

2. Minimum Value with Condition
// Get the lowest salary for employees in a specific department
deptId = 5;
lowestSalary = model(&quot;employee&quot;).minimum(
    property=&quot;salary&quot;,
    where=&quot;departmentId=#deptId#&quot;
);
writeOutput(&quot;Lowest Salary in Department #deptId#: &quot; &amp; lowestSalary);
// inline: writeOutput(model(&quot;employee&quot;).minimum(property=&quot;salary&quot;, where=&quot;departmentId=5&quot;));

3. Minimum Value with Range and Fallback
// Get the lowest salary within a range and fallback to 0 if no records
lowestSalary = model(&quot;employee&quot;).minimum(
    property=&quot;salary&quot;,
    where=&quot;salary BETWEEN #params.min# AND #params.max#&quot;,
    ifNull=0
);
writeOutput(&quot;Lowest Salary in range: &quot; &amp; lowestSalary);
// inline: writeOutput(model(&quot;employee&quot;).minimum(property=&quot;salary&quot;, where=&quot;salary BETWEEN #params.min# AND #params.max#&quot;, ifNull=0));

4. Including Associations
// Get the lowest product price including related categories
lowestPrice = model(&quot;product&quot;).minimum(
    property=&quot;price&quot;,
    include=&quot;category&quot;
);
writeOutput(&quot;Lowest Product Price: &quot; &amp; lowestPrice);
// inline: writeOutput(model(&quot;product&quot;).minimum(property=&quot;price&quot;, include=&quot;category&quot;));

5. Include Soft-Deleted Records
// Include soft-deleted employees in the calculation
lowestSalary = model(&quot;employee&quot;).minimum(
    property=&quot;salary&quot;,
    includeSoftDeletes=true
);
writeOutput(&quot;Lowest Salary including soft-deleted employees: &quot; &amp; lowestSalary);
// inline: writeOutput(model(&quot;employee&quot;).minimum(property=&quot;salary&quot;, includeSoftDeletes=true));</code></pre>
