---
title: viteAsset()
description: "Returns the resolved URL for a Vite entrypoint. In production, reads the Vite manifest"
sidebar:
  label: viteAsset()
  order: 0
---

## Signature

`viteAsset()` — returns `string`

**Available in:** `controller`
**Category:** Asset Functions

## Description

Returns the resolved URL for a Vite entrypoint. In production, reads the Vite manifest
to return the fingerprinted asset path. In development, returns the Vite dev server URL.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `entrypoint` | `string` | yes | — | The source entrypoint path as defined in your Vite config (e.g. "src/main.js"). |

</div>

