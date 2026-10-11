---
title: flashKeyExists()
description: "Checks if a specific key exists in the Flash."
sidebar:
  label: flashKeyExists()
  order: 0
---

## Signature

`flashKeyExists()` — returns `boolean`

**Available in:** `controller`
**Category:** Flash Functions

## Description

Checks if a specific key exists in the Flash.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `string` | yes | — | The key to check. |

</div>

## Examples

<pre><code class='javascript'>// 1. Check for an &quot;error&quot; key before reading it
if (flashKeyExists(&quot;error&quot;)) {
    errorMessage = flash(&quot;error&quot;);
}

// 2. Conditionally display a success notice
if (flashKeyExists(&quot;success&quot;)) {
    writeOutput(flash(&quot;success&quot;));
}

// 3. Guard before deleting a specific flash key
if (flashKeyExists(&quot;notice&quot;)) {
    flashDelete(&quot;notice&quot;);
}
</code></pre>
