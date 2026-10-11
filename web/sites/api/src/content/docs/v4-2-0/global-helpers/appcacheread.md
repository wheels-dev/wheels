---
title: appCacheRead()
description: "Returns the value cached under <code>key</code>, or <code>defaultValue</code> when there is no unexpired entry. A cached"
sidebar:
  label: appCacheRead()
  order: 0
---

## Signature

`appCacheRead()` — returns `any`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Caching Functions

## Description

Returns the value cached under <code>key</code>, or <code>defaultValue</code> when there is no unexpired entry. A cached
<code>false</code>, <code>0</code> or <code>""</code> is returned as it is. Complex values come back as a copy.
Keys are shared by every user, session, tenant and host (see <code>appCacheFetch()</code>).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | yes | — | A string, or a struct or array of values (struct key order doesn't matter). |
| `defaultValue` | `any` | no | — | What to return on a miss. The named argument `default` is also accepted. |

</div>

