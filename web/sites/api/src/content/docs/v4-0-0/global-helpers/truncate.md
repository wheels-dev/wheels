---
title: truncate()
description: "Truncates text to the specified length and replaces the last characters with the specified truncate string (which defaults to \"...\")."
sidebar:
  label: truncate()
  order: 0
---

## Signature

`truncate()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Truncates text to the specified length and replaces the last characters with the specified truncate string (which defaults to "...").



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to truncate. |
| `length` | `numeric` | no | `30` | Length to truncate the text to. |
| `truncateString` | `string` | no | `...` | String to replace the last characters with. |

</div>

