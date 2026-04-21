---
title: get()
description: "Returns the current setting for the supplied CFWheels setting or the current default for the supplied CFWheels function argument."
sidebar:
  label: get()
  order: 0
---

## Signature

`get()` — returns `any`

**Available in:** `controller`, `model`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Returns the current setting for the supplied CFWheels setting or the current default for the supplied CFWheels function argument.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Variable name to get setting for. |
| `functionName` | `string` | no | — | Function name to get setting for. |

</div>

## Examples

<pre><code class='javascript'>// Get the current value for the `tableNamePrefix` Wheels setting
setting = get(&quot;tableNamePrefix&quot;);

// Get the default for the `message` argument of the `validatesConfirmationOf` method
setting = get(functionName=&quot;validatesConfirmationOf&quot;, name=&quot;message&quot;);</code></pre>
