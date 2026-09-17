---
title: whereSlug()
description: "Constrain a route variable to only match URL-friendly slug values (lowercase alphanumeric and hyphens)."
sidebar:
  label: whereSlug()
  order: 0
---

## Signature

`whereSlug()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Constrain a route variable to only match URL-friendly slug values (lowercase alphanumeric and hyphens).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `variableName` | `string` | yes | — | The route variable name to constrain. Can also be a comma-delimited list. |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    // 1. Constrain a single slug variable — matches &quot;my-article-title&quot; but not &quot;My Article&quot; or &quot;abc123!&quot;
    .get(name=&quot;article&quot;, to=&quot;articles##show&quot;)
    .whereSlug(&quot;slug&quot;)

    // 2. Chain with another constraint helper after a resource route
    .resources(name=&quot;posts&quot;)
    .whereSlug(&quot;postSlug&quot;)

    // 3. Constrain multiple slug variables at once using a comma-delimited list
    .get(name=&quot;categoryPost&quot;, pattern=&quot;[category]/[postSlug]&quot;, to=&quot;posts##showByCategory&quot;)
    .whereSlug(&quot;category,postSlug&quot;)
.end();

&lt;/cfscript&gt;
</code></pre>
