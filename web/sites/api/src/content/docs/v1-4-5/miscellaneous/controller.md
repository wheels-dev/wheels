---
title: controller()
description: "Creates and returns a controller object with your own custom name and params. Used primarily for testing purposes."
sidebar:
  label: controller()
  order: 0
---

## Signature

`controller()` — returns `any`




## Description

Creates and returns a controller object with your own custom name and params. Used primarily for testing purposes.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the controller to create. |
| `params` | `struct` | yes | `[runtime expression]` | The params struct (combination of form and URL variables). |

</div>

## Examples

<pre>controller(name [, params ]) &lt;cfset testController = controller(&quot;users&quot;, params)&gt;</pre>
