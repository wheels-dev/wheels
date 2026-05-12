---
title: vitePreloadTag()
description: "Returns <code><link rel=\"modulepreload\"></code> tags for a Vite entrypoint and its transitive"
sidebar:
  label: vitePreloadTag()
  order: 0
---

## Signature

`vitePreloadTag()` — returns `string`

**Available in:** `controller`
**Category:** Asset Functions

## Description

Returns <code><link rel="modulepreload"></code> tags for a Vite entrypoint and its transitive
chunk imports. Useful for Turbo Drive hover-preload patterns or for explicitly warming
assets a subsequent navigation will need.
In development mode, returns an empty string — Vite handles module resolution
dynamically and modulepreload is unnecessary.


emits via <code>$viteHtmlHead()</code> so tags land in <code><head></code>.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `entrypoint` | `string` | yes | — | The source entrypoint path (e.g. "src/main.js"). |
| `head` | `boolean` | no | `true` | Set to `false` to return the markup for inline placement; default `true` |

</div>

