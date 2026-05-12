---
title: mimeTypes()
description: "Returns an associated MIME type based on a file extension."
sidebar:
  label: mimeTypes()
  order: 0
---

## Signature

`mimeTypes()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Returns an associated MIME type based on a file extension.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `extension` | `string` | yes | — | The extension to get the MIME type for. |
| `fallback` | `string` | no | `application/octet-stream` | The fallback MIME type to return. |

</div>

