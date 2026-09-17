---
title: setFlashStorage()
description: "Dynamically sets flashStorage during request lifecycle."
sidebar:
  label: setFlashStorage()
  order: 0
---

## Signature

`setFlashStorage()` — returns `void`

**Available in:** `controller`
**Category:** Flash Functions

## Description

Dynamically sets flashStorage during request lifecycle.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `storage` | `string` | no | `session` | Accepts "session" or "cookie" |
| `setGlobally` | `boolean` | no | `false` | If true, updates both app-level and controller-level flashStorage |

</div>

## Examples

<pre><code class='javascript'>// 1. Switch flash storage to cookie for the current request only
setFlashStorage(storage=&quot;cookie&quot;);
flashInsert(notice=&quot;Switching to cookie-based flash.&quot;);

// 2. Switch flash storage to session (the default) for the current request only
setFlashStorage(storage=&quot;session&quot;);

// 3. Update flash storage globally so all subsequent requests also use cookie storage
setFlashStorage(storage=&quot;cookie&quot;, setGlobally=true);
</code></pre>
