---
title: env()
description: "Returns the value of an environment variable. Checks application.env (loaded from .env files) first, then falls back to system environment variables (server.sys"
sidebar:
  label: env()
  order: 0
---

## Signature

`env()` — returns `any`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Returns the value of an environment variable. Checks application.env (loaded from .env files) first, then falls back to system environment variables (server.system.environment). Returns the default if the variable is not found in either location.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | The environment variable name to look up. |
| `default` | `any` | no | — | Value to return if the variable is not found. |

</div>

