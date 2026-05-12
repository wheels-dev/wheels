---
title: h()
description: "Encodes a value for safe HTML output. Use in templates to prevent XSS:"
sidebar:
  label: h()
  order: 0
---

## Signature

`h()` — returns `string`

**Available in:** `controller`
**Category:** Sanitization Functions

## Description

Encodes a value for safe HTML output. Use in templates to prevent XSS:
<code>#h(user.name)#</code> instead of <code>#user.name#</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `value` | `any` | yes | — | The value to encode for HTML output. Converted to string if not already. |

</div>

