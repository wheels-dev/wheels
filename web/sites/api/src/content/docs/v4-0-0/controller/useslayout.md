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

