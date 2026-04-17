---
title: onlyProvides()
description: "Use this in an individual controller action to define which formats the action will respond with. This can be used to define provides behavior in individual act"
sidebar:
  label: onlyProvides()
  order: 0
---

## Signature

`onlyProvides()` — returns `any`




## Description

Use this in an individual controller action to define which formats the action will respond with. This can be used to define provides behavior in individual actions or to override a global setting set with provides in the controller's init().

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `formats` | `string` | yes | — | See documentation for provides. |
| `action` | `string` | yes | — | Name of action, defaults to current. |

## Examples

<pre>// This will only provide the `html` type and will ignore what was defined in the call to `provides()` in the `init()` function
onlyProvides(&quot;html&quot;);</pre>
