---
title: usesLayout()
description: "Used within a controller's init() function to specify controller- or action-specific layouts."
sidebar:
  label: usesLayout()
  order: 0
---

## Signature

`usesLayout()` — returns `any`




## Description

Used within a controller's init() function to specify controller- or action-specific layouts.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `template` | `string` | yes | — | Name of the layout template or function name you want to use. |
| `ajax` | `string` | yes | — | Name of the layout template you want to use for AJAX requests. |
| `except` | `string` | yes | — | List of actions that should not get the layout. |
| `only` | `string` | yes | — | List of actions that should only get the layout. |
| `useDefault` | `boolean` | yes | `true` | When specifying conditions or a function, pass true to use the default layout.cfm if none of the conditions are met. |

## Examples

<pre>// We want this layout to be used as the default throughout the // entire controller, except for the `myAjax` action. usesLayout(template=&quot;myLayout&quot;, except=&quot;myAjax&quot;); // Use a custom layout for these actions but use the default // `layout.cfm` for the rest. usesLayout(template=&quot;myLayout&quot;, only=&quot;termsOfService,shippingPolicy&quot;); // Define a custom function to decide which layout to display. // // The `setLayout` function should return the name of the layout // to use or `true` to use the default one. usesLayout(&quot;setLayout&quot;);</pre>
