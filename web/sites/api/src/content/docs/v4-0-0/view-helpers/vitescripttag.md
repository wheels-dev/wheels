---
title: viteScriptTag()
description: "Returns 'script' tags for a Vite JS entrypoint. In development, also injects the Vite"
sidebar:
  label: viteScriptTag()
  order: 0
---

## Signature

`viteScriptTag()` — returns `string`

**Available in:** `controller`
**Category:** Asset Functions

## Description

Returns 'script' tags for a Vite JS entrypoint. In development, also injects the Vite
client for Hot Module Replacement (HMR). In production, includes any associated CSS files
from the manifest as <code><link></code> tags.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `entrypoint` | `string` | yes | — | The source entrypoint path (e.g. "src/main.js"). |
| `head` | `boolean` | no | `false` | Set to `true` to place output in the `<head>` area instead of inline. |

</div>

