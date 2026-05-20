---
title: hAttr()
description: "Encodes a value for safe use inside an HTML attribute."
sidebar:
  label: hAttr()
  order: 0
---

## Signature

`hAttr()` — returns `string`

**Available in:** `controller`
**Category:** Sanitization Functions

## Description

Encodes a value for safe use inside an HTML attribute.
Use when building attribute values manually:
&lt;div title="#hAttr(user.bio)#"&gt;.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `value` | `any` | yes | — | The value to encode for HTML attribute context. |

</div>

