---
title: escapeForLike()
description: "Escapes the <code>LIKE</code> wildcards in a string so it can be used as a literal search term in a"
sidebar:
  label: escapeForLike()
  order: 0
---

## Signature

`escapeForLike()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Escapes the <code>LIKE</code> wildcards in a string so it can be used as a literal search term in a
<code>LIKE</code> comparison that declares <code>ESCAPE '\'</code>. The escape character <code>\</code> is escaped first, then
<code>%</code> and <code>_</code>; `


## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `value` | `string` | yes | — | String whose `LIKE` wildcards should be treated as literals. |

</div>

