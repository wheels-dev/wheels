---
title: setFlashStorage()
description: "Dynamically sets flashStorage during request lifecycle."
sidebar:
  label: setFlashStorage()
  order: 0
---

## Signature

`setFlashStorage()` — returns `void`

**Available in:** `controller`
**Category:** Flash Functions

## Description

Dynamically sets flashStorage during request lifecycle.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `storage` | `string` | no | `session` | Accepts "session" or "cookie" |
| `setGlobally` | `boolean` | no | `false` | If true, updates both app-level and controller-level flashStorage |

</div>

