---
title: sum()
description: "Calculates the total of all values for a given property (column) using SQL’s <code>SUM()</code> function. It’s typically used to aggregate numeric values across"
sidebar:
  label: sum()
  order: 0
---

## Signature

`sum()` — returns `any`

**Available in:** `model`
**Category:** Statistics Functions

## Description

Calculates the total of all values for a given property (column) using SQL’s <code>SUM()</code> function. It’s typically used to aggregate numeric values across a set of records (e.g., summing salaries, prices, or quantities). You can add filtering with where, group results with group, or join associations using include. If no records are found, use the ifNull argument to return a safe default (commonly 0 for numeric sums).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of the property to get the sum for (must be a property of a numeric data type). |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. Nested queries not allowed. You do not need to specify the table name(s); Wheels will do that for you. |
| `include` | `string` | no | — | Associations that should be included in the query using `INNER` or `LEFT OUTER` joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. `department,addresses,emails`). You can build more complex include strings by using parentheses when the association is set on an included model, like `album(artist(genre))`, for example. These complex `include` strings only work when `returnAs` is set to `query` though. |
| `distinct` | `boolean` | no | `false` | When true, SUM returns the sum of unique values only. |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `ifNull` | `any` | no | — | The value returned if no records are found. Common usage is to set this to `0` to make sure a numeric value is always returned instead of a blank string. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |
| `group` | `string` | no | — | Maps to the `GROUP BY` clause of the query. You do not need to specify the table name(s); Wheels will do that for you. |

</div>

## Examples

<pre><code class='javascript'>1. Basic sum
allSalaries = model(&quot;employee&quot;).sum(&quot;salary&quot;);

2. With filtering (where)
allAustralianSalaries = model(&quot;employee&quot;).sum(
 property=&quot;salary&quot;,
 include=&quot;country&quot;,
 where=&quot;countryname='Australia'&quot;
);

3. With ifNull safeguard
salarySum = model(&quot;employee&quot;).sum(
 property=&quot;salary&quot;,
 where=&quot;salary BETWEEN #params.min# AND #params.max#&quot;,
 ifNull=0
);

4. Sum with grouping
salariesByDept = model(&quot;employee&quot;).sum(
 property=&quot;salary&quot;,
 group=&quot;departmentId&quot;
);

5. Distinct sum
uniqueSalaries = model(&quot;employee&quot;).sum(
 property=&quot;salary&quot;,
 distinct=true
);
</code></pre>
