---
title: addFormat()
description: "Adds a new MIME type to your Wheels application for use with responding to multiple formats."
sidebar:
  label: addFormat()
  order: 0
---

## Signature

`addFormat()` — returns `void`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Adds a new MIME type to your Wheels application for use with responding to multiple formats.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `extension` | `string` | yes | — | File extension to add. |
| `mimeType` | `string` | yes | — | Matching MIME type to associate with the file extension. |

</div>

