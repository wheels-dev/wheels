---
title: viteStyleTag()
description: "Returns a <code><link></code> tag for a Vite CSS entrypoint. In development, Vite injects CSS via"
sidebar:
  label: viteStyleTag()
  order: 0
---

## Signature

`viteStyleTag()` — returns `string`

**Available in:** `controller`
**Category:** Asset Functions

## Description

Returns a <code><link></code> tag for a Vite CSS entrypoint. In development, Vite injects CSS via
the JS client so this returns an empty string. In production, resolves the fingerprinted path.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `entrypoint` | `string` | yes | — | The source CSS entrypoint path (e.g. "src/main.css"). |
| `head` | `boolean` | no | `false` | Set to `true` to place output in the `<head>` area instead of inline. |

</div>

