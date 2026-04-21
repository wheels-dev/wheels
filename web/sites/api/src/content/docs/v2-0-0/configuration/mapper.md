---
title: mapper()
description: "Returns the mapper object used to configure your application's routes. Usually you will use this method in <code>config/routes.cfm</code> to start chaining rout"
sidebar:
  label: mapper()
  order: 0
---

## Signature

`mapper()` — returns `struct`

**Available in:** `controller`, `model`, `migrator`
**Category:** Routing

## Description

Returns the mapper object used to configure your application's routes. Usually you will use this method in <code>config/routes.cfm</code> to start chaining route mapping methods like <code>resources</code>, <code>namespace</code>, etc.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `restful` | `boolean` | no | `true` |  |
| `methods` | `boolean` | no | `[runtime expression]` |  |

</div>

