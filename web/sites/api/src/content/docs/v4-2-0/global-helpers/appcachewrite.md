---
title: appCacheWrite()
description: "Caches <code>value</code> under <code>key</code> for <code>time</code>, replacing any entry already there. Complex values are"
sidebar:
  label: appCacheWrite()
  order: 0
---

## Signature

`appCacheWrite()` — returns `boolean`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Caching Functions

## Description

Caches <code>value</code> under <code>key</code> for <code>time</code>, replacing any entry already there. Complex values are
stored as a copy. Returns <code>false</code> when the value wasn't stored because the cache is full
(<code>maximumItemsToCache</code>).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | yes | — | A string, or a struct or array of values (struct key order doesn't matter). |
| `value` | `any` | yes | — | The value to cache. |
| `time` | `numeric` | no | `[runtime expression]` | How long to keep the value, in `cacheDatePart` units (minutes by default). |

</div>

