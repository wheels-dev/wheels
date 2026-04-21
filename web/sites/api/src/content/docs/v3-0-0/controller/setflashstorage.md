---
title: setFlashStorage()
description: "Dynamically sets the storage mechanism for flash messages during the current request lifecycle. Flash messages are temporary messages (e.g., success or error no"
sidebar:
  label: setFlashStorage()
  order: 0
---

## Signature

`setFlashStorage()` — returns `void`

**Available in:** `controller`
**Category:** Flash Functions

## Description

Dynamically sets the storage mechanism for flash messages during the current request lifecycle. Flash messages are temporary messages (e.g., success or error notifications) that persist across requests.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `storage` | `string` | no | `session` | Specifies the storage mechanism for flash data. Available options: session or cookie. |
| `setGlobally` | `boolean` | no | `false` | If set to true, updates both application-level and controller-level flashStorage; otherwise, only the controller-level flashStorage is updated. |

</div>

## Examples

<pre><code class='javascript'>1. Set the flash to cookie for the current controller only.
setFlashStorage(&quot;cookie&quot;);

2. Set the flash to session for the current controller and application
setFlashStorage(&quot;session&quot;, true);</code></pre>
