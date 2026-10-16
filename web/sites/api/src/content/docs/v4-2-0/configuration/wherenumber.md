---
title: whereNumber()
description: "Constrain a route variable to only match numeric values (digits). Similar to Laravel's <code>whereNumber()</code> or ASP.NET's <code>:int</code> constraint."
sidebar:
  label: whereNumber()
  order: 0
---

## Signature

`whereNumber()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Constrain a route variable to only match numeric values (digits). Similar to Laravel's <code>whereNumber()</code> or ASP.NET's <code>:int</code> constraint.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `variableName` | `string` | yes | — | The route variable name to constrain (e.g., `"id"`). Can also be a comma-delimited list to constrain multiple variables. |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    // 1. Constrain a single route variable to numeric digits only
    //    The [id] segment will only match values like &quot;1&quot;, &quot;42&quot;, &quot;1000&quot;
    .get(name=&quot;article&quot;, pattern=&quot;articles/[id]&quot;, to=&quot;articles##show&quot;)
    .whereNumber(&quot;id&quot;)

    // 2. Constrain multiple variables at once using a comma-delimited list
    //    Both [year] and [month] must contain only digit characters
    .get(name=&quot;archiveMonth&quot;, pattern=&quot;archive/[year]/[month]&quot;, to=&quot;posts##archive&quot;)
    .whereNumber(&quot;year,month&quot;)

    // 3. Chain with other constraint helpers for mixed-type route variables
    //    [category] must be alphabetic; [id] must be numeric
    .get(name=&quot;categoryItem&quot;, pattern=&quot;[category]/[id]&quot;, to=&quot;items##show&quot;)
    .whereAlpha(&quot;category&quot;)
    .whereNumber(&quot;id&quot;)
.end();

&lt;/cfscript&gt;
</code></pre>
