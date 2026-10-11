---
title: whereAlphaNumeric()
description: "Constrain a route variable to only match alphanumeric characters (a-zA-Z0-9). Similar to Laravel's <code>whereAlphaNumeric()</code>."
sidebar:
  label: whereAlphaNumeric()
  order: 0
---

## Signature

`whereAlphaNumeric()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Constrain a route variable to only match alphanumeric characters (a-zA-Z0-9). Similar to Laravel's <code>whereAlphaNumeric()</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `variableName` | `string` | yes | — | The route variable name to constrain. Can also be a comma-delimited list. |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    // 1. Constrain a single route variable to alphanumeric characters only
    .get(name=&quot;profile&quot;, pattern=&quot;profiles/[username]&quot;, to=&quot;profiles##show&quot;)
    .whereAlphaNumeric(&quot;username&quot;)

    // 2. Constrain multiple variables to alphanumeric in one call (comma-delimited list)
    .get(name=&quot;teamMember&quot;, pattern=&quot;teams/[teamCode]/members/[memberCode]&quot;, to=&quot;teams##member&quot;)
    .whereAlphaNumeric(&quot;teamCode,memberCode&quot;)

    // 3. Chain whereAlphaNumeric with a resources block to restrict the key variable
    .resources(name=&quot;products&quot;)
    .whereAlphaNumeric(&quot;key&quot;)
.end();

&lt;/cfscript&gt;
</code></pre>
