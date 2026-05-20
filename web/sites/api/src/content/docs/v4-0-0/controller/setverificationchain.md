---
title: setVerificationChain()
description: "Use this function if you need a more low level way of setting the entire verification chain for a controller."
sidebar:
  label: setVerificationChain()
  order: 0
---

## Signature

`setVerificationChain()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Use this function if you need a more low level way of setting the entire verification chain for a controller.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `chain` | `array` | yes | — | An array of structs, each of which represent an `argumentCollection` that get passed to the `verifies` function. This should represent the entire verification chain that you want to use for this controller. |

</div>

