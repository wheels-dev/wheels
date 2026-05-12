---
title: usesLayout()
description: "Used inside a controller's <code>config()</code> function to specify which layout template should be applied to the controller or specific actions. You can defi"
sidebar:
  label: usesLayout()
  order: 0
---

## Signature

`usesLayout()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Used inside a controller's <code>config()</code> function to specify which layout template should be applied to the controller or specific actions. You can define a default layout for the entire controller, specify layouts only for certain actions, exclude specific actions from using a layout, or even provide a custom function to determine which layout to use dynamically. This allows fine-grained control over your page structure and helps maintain consistent design while accommodating exceptions.



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

<pre><code class='javascript'>1. We want this layout to be used as the default throughout the entire controller, except for the `myAjax` action. 
usesLayout(template=&quot;myLayout&quot;, except=&quot;myAjax&quot;); 

2. Use a custom layout for these actions but use the default `layout.cfm` for the rest. 
usesLayout(template=&quot;myLayout&quot;, only=&quot;termsOfService,shippingPolicy&quot;); 

3. Define a custom function to decide which layout to display.
// The `setLayout` function should return the name of the layout to use or `true` to use the default one. 
usesLayout(&quot;setLayout&quot;);</code></pre>
