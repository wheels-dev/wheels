---
title: mapper()
description: "Returns the mapper object used to configure your application's routes. Usually you will use this method in <code>config/routes.cfm</code> to start chaining rout"
sidebar:
  label: mapper()
  order: 0
---

## Signature

`mapper()` — returns `struct`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Routing

## Description

Returns the mapper object used to configure your application's routes. Usually you will use this method in <code>config/routes.cfm</code> to start chaining route mapping methods like <code>resources</code>, <code>namespace</code>, etc.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `restful` | `boolean` | no | `true` | Whether to turn on RESTful routing or not. Not recommended to set. Will probably be removed in a future version of wheels, as RESTful routes are the default. |
| `methods` | `boolean` | no | `[runtime expression]` | If not RESTful, then specify allowed routes. Not recommended to set. Will probably be removed in a future version of wheels, as RESTful routes are the default. |
| `mapFormat` | `boolean` | no | `true` | This is useful for providing formats via URL like `json`, `xml`, `pdf`, etc. Set to false to disable automatic .[format] generation for resource based routes |

</div>

