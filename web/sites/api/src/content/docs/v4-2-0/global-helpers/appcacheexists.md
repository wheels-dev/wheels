---
title: appCacheExists()
description: "Returns <code>true</code> when an unexpired entry exists for <code>key</code>, even one holding <code>false</code>, <code>0</code> or <code>\"\"</code>."
sidebar:
  label: appCacheExists()
  order: 0
---

## Signature

`appCacheExists()` — returns `boolean`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Caching Functions

## Description

Returns <code>true</code> when an unexpired entry exists for <code>key</code>, even one holding <code>false</code>, <code>0</code> or <code>""</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | yes | — | A string, or a struct or array of values (struct key order doesn't matter). |

</div>

