---
title: filters()
description: "Tells Wheels to run a function before an action is run or after an action has been run."
sidebar:
  label: filters()
  order: 0
---

## Signature

`filters()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Tells Wheels to run a function before an action is run or after an action has been run.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `through` | `string` | yes | — | Function(s) to execute before or after the action(s). |
| `type` | `string` | no | `before` | Whether to run the function(s) before or after the action(s). |
| `only` | `string` | no | — | Pass in a list of action names (or one action name) to tell Wheels that the filter function(s) should only be run on these actions. |
| `except` | `string` | no | — | Pass in a list of action names (or one action name) to tell Wheels that the filter function(s) should be run on all actions except the specified ones. |
| `placement` | `string` | no | `append` | Pass in `prepend` to prepend the function(s) to the filter chain instead of appending. |

</div>

