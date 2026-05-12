---
title: inject()
description: "Declare one or more services for injection into this controller."
sidebar:
  label: inject()
  order: 0
---

## Signature

`inject()` — returns `void`

**Available in:** `controller`


## Description

Declare one or more services for injection into this controller.
Call in config(). Services are resolved when the controller instance is created.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Comma-delimited list of registered service names to inject. |

</div>

