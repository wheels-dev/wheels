---
title: humanize()
description: "Returns readable text by capitalizing and converting camel casing to multiple words."
sidebar:
  label: humanize()
  order: 0
---

## Signature

`humanize()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Returns readable text by capitalizing and converting camel casing to multiple words.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | Text to humanize. |
| `except` | `string` | no | — | A list of strings (space separated) to replace within the output. |

</div>

