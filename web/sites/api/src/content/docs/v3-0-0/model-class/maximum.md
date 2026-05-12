---
title: maximum()
description: "Calculates the maximum value for a given property."
sidebar:
  label: maximum()
  order: 0
---

## Signature

`maximum()` — returns `any`

**Available in:** `model`
**Category:** Statistics Functions

## Description

Calculates the maximum value for a given property.
Uses the SQL function <code>MAX</code>.
If no records can be found to perform the calculation on you can use the <code>ifNull</code> argument to decide what should be returned.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of the property to get the highest value for (must be a property of a numeric data type). |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. Nested queries not allowed. You do not need to specify the table name(s); Wheels will do that for you. |
| `include` | `string` | no | — | Associations that should be included in the query using `INNER` or `LEFT OUTER` joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. `department,addresses,emails`). You can build more complex include strings by using parentheses when the association is set on an included model, like `album(artist(genre))`, for example. These complex `include` strings only work when `returnAs` is set to `query` though. |
| `parameterize` | `any` | no | `true` |  |
| `ifNull` | `any` | no | — | The value returned if no records are found. Common usage is to set this to `0` to make sure a numeric value is always returned instead of a blank string. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |
| `group` | `string` | no | — | Maps to the `GROUP BY` clause of the query. You do not need to specify the table name(s); Wheels will do that for you. |

</div>

## Examples

<pre><code class='javascript'>1. Maximum value for all records
highestSalary = model(&quot;employee&quot;).maximum(&quot;salary&quot;);
// one-liner: highestSalary = model(&quot;employee&quot;).maximum(&quot;salary&quot;);

2. Maximum value with a WHERE condition
highestSalary = model(&quot;employee&quot;).maximum(
    property=&quot;salary&quot;, 
    where=&quot;departmentId=#params.departmentId#&quot;
);
// one-liner: highestSalary = model(&quot;employee&quot;).maximum(property=&quot;salary&quot;, where=&quot;departmentId=#params.departmentId#&quot;);

3. Maximum value with a default if no records found
highestSalary = model(&quot;employee&quot;).maximum(
    property=&quot;salary&quot;, 
    where=&quot;salary &gt; #params.minSalary#&quot;, 
    ifNull=0
);
// one-liner: highestSalary = model(&quot;employee&quot;).maximum(property=&quot;salary&quot;, where=&quot;salary &gt; #params.minSalary#&quot;, ifNull=0);

4. Maximum value including associations (nested join)
highestAlbumSales = model(&quot;album&quot;).maximum(
    property=&quot;sales&quot;,
    include=&quot;artist(genre)&quot;
);
// one-liner: highestAlbumSales = model(&quot;album&quot;).maximum(property=&quot;sales&quot;, include=&quot;artist(genre)&quot;);

5. Maximum value grouped by a column
maxSalaryByDept = model(&quot;employee&quot;).maximum(
    property=&quot;salary&quot;,
    group=&quot;departmentId&quot;
);
// one-liner: maxSalaryByDept = model(&quot;employee&quot;).maximum(property=&quot;salary&quot;, group=&quot;departmentId&quot;);</code></pre>
