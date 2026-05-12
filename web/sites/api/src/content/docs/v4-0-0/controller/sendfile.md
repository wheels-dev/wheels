---
title: sendFile()
description: "Sends a file to the user (from the <code>files</code> folder or a path relative to it by default)."
sidebar:
  label: sendFile()
  order: 0
---

## Signature

`sendFile()` — returns `any`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Sends a file to the user (from the <code>files</code> folder or a path relative to it by default).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `file` | `string` | yes | — | The file to send to the user. |
| `name` | `string` | no | — | The file name to show in the browser download dialog box. |
| `type` | `string` | no | — | The HTTP content type to deliver the file as. |
| `disposition` | `string` | no | `attachment` | Set to `inline` to have the browser handle the opening of the file (possibly inline in the browser) or set to `attachment` to force a download dialog box. |
| `directory` | `string` | no | — | Directory outside of the web root where the file exists. Must be a full path. |
| `deleteFile` | `boolean` | no | `false` | Pass in `true` to delete the file on the server after sending it. |
| `deliver` | `boolean` | no | `true` |  |

</div>

