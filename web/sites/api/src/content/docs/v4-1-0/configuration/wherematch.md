---
title: whereMatch()
description: "Constrain a route variable with a custom regex pattern."
sidebar:
  label: whereMatch()
  order: 0
---

## Signature

`whereMatch()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Constrain a route variable with a custom regex pattern.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `variableName` | `string` | yes | — | The route variable name to constrain. |
| `pattern` | `string` | yes | — | The regex pattern the variable must match. |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    // 1. Constrain a route variable to a custom regex pattern (year: 4-digit number)
    .get(name=&quot;archiveYear&quot;, pattern=&quot;archive/[year]&quot;, to=&quot;posts##archiveByYear&quot;)
    .whereMatch(variableName=&quot;year&quot;, pattern=&quot;\d{4}&quot;)

    // 2. Constrain a slug variable to lowercase letters and hyphens only
    .get(name=&quot;articleShow&quot;, pattern=&quot;articles/[slug]&quot;, to=&quot;articles##show&quot;)
    .whereMatch(variableName=&quot;slug&quot;, pattern=&quot;[a-z][a-z0-9-]+&quot;)

    // 3. Chained with resources — constrain the key to a specific format (e.g. SKU like AB-12345)
    .resources(&quot;products&quot;)
    .whereMatch(variableName=&quot;key&quot;, pattern=&quot;[A-Z]{2}-\d{5}&quot;)
.end();

&lt;/cfscript&gt;
</code></pre>
