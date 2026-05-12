---
title: timeAgoInWords()
description: "Returns a string describing the approximate time difference between the date passed in and the current date."
sidebar:
  label: timeAgoInWords()
  order: 0
---

## Signature

`timeAgoInWords()` — returns `any`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Date Functions

## Description

Returns a string describing the approximate time difference between the date passed in and the current date.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `fromTime` | `date` | yes | — | Date to compare from. |
| `includeSeconds` | `boolean` | no | `false` | Whether or not to include the number of seconds in the returned string. |
| `toTime` | `date` | no | `[runtime expression]` | Date to compare to. |

</div>

