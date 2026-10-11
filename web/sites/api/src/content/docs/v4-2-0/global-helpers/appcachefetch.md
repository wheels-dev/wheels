---
title: appCacheFetch()
description: "Returns the value cached under <code>key</code>. On a miss, calls <code>callback</code>, caches what it returns for <code>time</code>"
sidebar:
  label: appCacheFetch()
  order: 0
---

## Signature

`appCacheFetch()` — returns `any`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Caching Functions

## Description

Returns the value cached under <code>key</code>. On a miss, calls <code>callback</code>, caches what it returns for <code>time</code>
and returns it. A cached <code>false</code>, <code>0</code> or <code>""</code> counts as a hit, so <code>callback</code> isn't called again
until the entry expires or is deleted. When <code>callback</code> returns nothing, nothing is cached and <code>""</code>
is returned; when it throws, nothing is cached and the error propagates. <code>callback</code> runs outside
the cache lock, so two requests that miss at the same moment may both call it (the later write
wins). When the cache is full, the computed value is returned but not cached, so the next call
computes it again. The cache lives in this server's memory and empties on an application reload
or restart.
Keys are shared by every user, session, tenant and host: nothing about the request is added. For
per-user, per-role or per-tenant data, put that identity in the key, e.g. <code>"digest-" & userId</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | yes | — | A string, or a struct or array of values (struct key order doesn't matter). |
| `callback` | `any` | yes | — | A function that computes the value. |
| `time` | `numeric` | no | `[runtime expression]` | How long to keep the value, in `cacheDatePart` units (minutes by default). |

</div>

