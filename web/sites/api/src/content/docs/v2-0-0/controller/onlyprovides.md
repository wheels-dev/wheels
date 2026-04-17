---
title: onlyProvides()
description: "Use this in an individual controller action to define which formats the action will respond with."
sidebar:
  label: onlyProvides()
  order: 0
---

## Signature

`onlyProvides()` — returns `void`

**Available in:** `controller`
**Category:** Provides Functions

## Description

Use this in an individual controller action to define which formats the action will respond with.
This can be used to define provides behavior in individual actions or to override a global setting set with <code>provides</code> in the controller's <code>config()</code>.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `formats` | `string` | no | — | Formats to instruct the controller to provide. Valid values are `html` (the default), `xml`, `json`, `csv`, `pdf`, and `xls`. |
| `action` | `string` | no | `[runtime expression]` | Name of action, defaults to current. |

## Examples

<pre>// This will only provide the `html` type and will ignore what was defined in the call to `provides()` in the `config()` function
onlyProvides(&quot;html&quot;);</pre>
