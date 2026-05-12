---
title: registerOnError()
description: "Registers a callback function to be invoked when an unhandled error occurs."
sidebar:
  label: registerOnError()
  order: 0
---

## Signature

`registerOnError()` — returns `void`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Error Handling

## Description

Registers a callback function to be invoked when an unhandled error occurs.
Callbacks receive a single argument: the exception struct.
Multiple callbacks are invoked in registration order. A failing callback
is logged and skipped — it will not prevent other callbacks from running.
Should be called during app initialization, not per-request.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `callback` | `function` | yes | — | A function that accepts an exception struct argument. Must complete quickly — long-running callbacks delay error responses. |

</div>

