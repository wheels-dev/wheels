---
title: flash()
description: "The flash() function is used in controllers to access data stored in the Flash scope. Flash is a temporary storage mechanism that lets you persist values across"
sidebar:
  label: flash()
  order: 0
---

## Signature

`flash()` — returns `any`

**Available in:** `controller`
**Category:** Flash Functions

## Description

The flash() function is used in controllers to access data stored in the Flash scope. Flash is a temporary storage mechanism that lets you persist values across the next request (often after a redirect). You can use it to retrieve a specific key or the entire Flash struct. If you pass in a key, it returns the value associated with it; if no key is passed, it returns all the Flash contents as a struct.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `string` | no | — | The key to get the value for. |

</div>

## Examples

<pre><code class='javascript'>1. Get a specific Flash value (commonly used for notifications or messages)

notice = flash(&quot;notice&quot;);

2. Get another value stored in Flash, e.g., an error message

errorMsg = flash(&quot;error&quot;);

3. Retrieve the entire Flash scope as a struct

allFlash = flash();
</code></pre>
