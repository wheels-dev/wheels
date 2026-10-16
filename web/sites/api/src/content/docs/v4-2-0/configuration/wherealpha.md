---
title: whereAlpha()
description: "Constrain a route variable to only match alphabetic characters (a-zA-Z). Similar to Laravel's <code>whereAlpha()</code> or ASP.NET's <code>:alpha</code> constra"
sidebar:
  label: whereAlpha()
  order: 0
---

## Signature

`whereAlpha()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Constrain a route variable to only match alphabetic characters (a-zA-Z). Similar to Laravel's <code>whereAlpha()</code> or ASP.NET's <code>:alpha</code> constraint.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `variableName` | `string` | yes | — | The route variable name to constrain. Can also be a comma-delimited list. |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    // 1. Constrain a single route variable to alphabetic characters only
    //    The [locale] segment will only match values like &quot;en&quot;, &quot;fr&quot;, &quot;de&quot;
    .get(name=&quot;localizedHome&quot;, pattern=&quot;[locale]/home&quot;, to=&quot;home##index&quot;)
    .whereAlpha(&quot;locale&quot;)

    // 2. Constrain multiple variables at once using a comma-delimited list
    //    Both [lang] and [region] must contain only a-z / A-Z characters
    .get(name=&quot;localizedPage&quot;, pattern=&quot;[lang]/[region]/[action]&quot;, to=&quot;pages##show&quot;)
    .whereAlpha(&quot;lang,region&quot;)

    // 3. Chain with other constraint helpers for mixed-type route variables
    //    [category] must be alphabetic; [id] must be numeric
    .resources(name=&quot;articles&quot;)
    .get(name=&quot;articleByCategory&quot;, pattern=&quot;articles/[category]/[id]&quot;, to=&quot;articles##byCategory&quot;)
    .whereAlpha(&quot;category&quot;)
    .whereNumber(&quot;id&quot;)
.end();

&lt;/cfscript&gt;
</code></pre>
