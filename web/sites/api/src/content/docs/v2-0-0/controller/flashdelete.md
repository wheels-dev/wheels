---
title: flashDelete()
description: "Deletes a specific key from the Flash."
sidebar:
  label: flashDelete()
  order: 0
---

## Signature

`flashDelete()` — returns `any`

**Available in:** `controller`
**Category:** Flash Functions

## Description

Deletes a specific key from the Flash.
Returns <code>true</code> if the key exists.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `string` | yes | — | The key to delete |

## Examples

<pre>flashDelete(key=&quot;errorMessage&quot;);</pre>
