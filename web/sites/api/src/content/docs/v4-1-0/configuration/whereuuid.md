---
title: whereUuid()
description: "Constrain a route variable to only match UUID values. Similar to ASP.NET's <code>:guid</code> constraint."
sidebar:
  label: whereUuid()
  order: 0
---

## Signature

`whereUuid()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Constrain a route variable to only match UUID values. Similar to ASP.NET's <code>:guid</code> constraint.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `variableName` | `string` | yes | — | The route variable name to constrain. Can also be a comma-delimited list. |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    // 1. Constrain a single route variable to UUID values only
    //    The [id] segment will only match values like &quot;550e8400-e29b-41d4-a716-446655440000&quot;
    .get(name=&quot;document&quot;, pattern=&quot;documents/[id]&quot;, to=&quot;documents##show&quot;)
    .whereUuid(&quot;id&quot;)

    // 2. Constrain multiple variables to UUID format using a comma-delimited list
    //    Both [userId] and [sessionId] must be valid UUID values
    .get(name=&quot;userSession&quot;, pattern=&quot;users/[userId]/sessions/[sessionId]&quot;, to=&quot;sessions##show&quot;)
    .whereUuid(&quot;userId,sessionId&quot;)

    // 3. Chain with other constraint helpers for mixed-type route variables
    //    [type] must be alphabetic; [id] must be a UUID
    .get(name=&quot;typedResource&quot;, pattern=&quot;resources/[type]/[id]&quot;, to=&quot;resources##show&quot;)
    .whereAlpha(&quot;type&quot;)
    .whereUuid(&quot;id&quot;)
.end();

&lt;/cfscript&gt;
</code></pre>
