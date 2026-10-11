---
title: appCacheDelete()
description: "Removes the entry for <code>key</code>. Returns <code>true</code> when there was an unexpired entry to remove."
sidebar:
  label: appCacheDelete()
  order: 0
---

## Signature

`appCacheDelete()` — returns `boolean`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Caching Functions

## Description

Removes the entry for <code>key</code>. Returns <code>true</code> when there was an unexpired entry to remove.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | yes | — | A string, or a struct or array of values (struct key order doesn't matter). |

</div>

