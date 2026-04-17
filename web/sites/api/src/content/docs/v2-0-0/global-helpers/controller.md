---
title: controller()
description: "Creates and returns a controller object with your own custom name and params."
sidebar:
  label: controller()
  order: 0
---

## Signature

`controller()` — returns `any`

**Available in:** `controller`, `model`, `migrator`
**Category:** Miscellaneous Functions

## Description

Creates and returns a controller object with your own custom name and params.
Used primarily for testing purposes.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the controller to create. |
| `params` | `struct` | no | `[runtime expression]` | The params struct (combination of form and URL variables). |

## Examples

<pre>testController = controller(&quot;users&quot;, params);</pre>
