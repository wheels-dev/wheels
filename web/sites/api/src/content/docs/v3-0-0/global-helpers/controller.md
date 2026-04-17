---
title: controller()
description: "The controller() function creates and returns a controller object with a custom name and optional parameters. It is primarily used for testing, but can also be"
sidebar:
  label: controller()
  order: 0
---

## Signature

`controller()` — returns `any`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

The controller() function creates and returns a controller object with a custom name and optional parameters. It is primarily used for testing, but can also be used in code to instantiate a controller programmatically. Unlike the deprecated routing controller() function, this helper does not define routes—it creates controller instances.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the controller to create. |
| `params` | `struct` | no | `[runtime expression]` | The params struct (combination of form and URL variables). |

## Examples

<pre><code class='javascript'>testController = controller(&quot;users&quot;, params);</code></pre>
