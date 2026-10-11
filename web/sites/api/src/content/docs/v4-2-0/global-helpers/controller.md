---
title: controller()
description: "Creates and returns a controller object with your own custom name and params."
sidebar:
  label: controller()
  order: 0
---

## Signature

`controller()` — returns `any`

**Available in:** `controller`, `model`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Creates and returns a controller object with your own custom name and params.
Used primarily for testing purposes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the controller to create. |
| `params` | `struct` | no | `[runtime expression]` | The params struct (combination of form and URL variables). |

</div>

## Examples

<pre><code class='javascript'>// 1. Create a controller object for testing (no params)
usersController = controller(&quot;users&quot;);

// 2. Create a controller object with simulated request params for testing
params = {controller = &quot;users&quot;, action = &quot;show&quot;, key = 1};
usersController = controller(name = &quot;users&quot;, params = params);

// 3. Use with processAction to test an action end-to-end
params = {controller = &quot;users&quot;, action = &quot;index&quot;};
usersController = controller(name = &quot;users&quot;, params = params);
usersController.processAction();
body = usersController.response();
</code></pre>
