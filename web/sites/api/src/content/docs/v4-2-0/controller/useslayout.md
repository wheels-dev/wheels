---
title: usesLayout()
description: "Used within a controller's <code>config()</code> function to specify controller- or action-specific layouts."
sidebar:
  label: usesLayout()
  order: 0
---

## Signature

`usesLayout()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Used within a controller's <code>config()</code> function to specify controller- or action-specific layouts.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `template` | `string` | yes | — | Name of the layout template or function name you want to use. |
| `ajax` | `string` | no | — | Name of the layout template you want to use for AJAX requests. |
| `except` | `string` | no | — | List of actions that should not get the layout. |
| `only` | `string` | no | — | List of actions that should only get the layout. |
| `useDefault` | `boolean` | no | `true` | When specifying conditions or a function, pass in `true` to use the default `layout.cfm` if none of the conditions are met. |

</div>

## Examples

<pre><code class='javascript'>// 1. Use a custom layout for the entire controller, except for one action.
// Declared inside the controller's config() function.
usesLayout(template=&quot;myLayout&quot;, except=&quot;myAjax&quot;);

// 2. Apply a custom layout only to specific actions; all other actions
// use the default layout.cfm.
usesLayout(template=&quot;myLayout&quot;, only=&quot;termsOfService,shippingPolicy&quot;);

// 3. Serve a lightweight layout for AJAX requests while normal requests
// still receive the full layout.
usesLayout(template=&quot;myLayout&quot;, ajax=&quot;ajaxLayout&quot;);

// 4. Delegate layout selection to a private function. The function receives
// the current action name and should return the layout template name or
// true to fall back to the default layout.cfm.
usesLayout(&quot;chooseLayout&quot;);

// Example chooseLayout() function in the same controller:
// private function chooseLayout(action) {
//   if (action == &quot;print&quot;) return &quot;printLayout&quot;;
//   return true; // fall back to default layout.cfm
// }

// 5. Use a function-based layout but fall back to layout.cfm when the
// function returns nothing (useDefault defaults to true).
usesLayout(template=&quot;chooseLayout&quot;, useDefault=true);
</code></pre>
