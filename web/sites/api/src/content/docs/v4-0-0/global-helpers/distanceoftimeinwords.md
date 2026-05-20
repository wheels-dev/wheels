---
title: distanceOfTimeInWords()
description: "Pass in two dates to this method, and it will return a string describing the difference between them."
sidebar:
  label: distanceOfTimeInWords()
  order: 0
---

## Signature

`distanceOfTimeInWords()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Date Functions

## Description

Pass in two dates to this method, and it will return a string describing the difference between them.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `fromTime` | `date` | yes | — | Date to compare from. |
| `toTime` | `date` | yes | — | Date to compare to. |
| `includeSeconds` | `boolean` | no | `false` | Whether or not to include the number of seconds in the returned string. |

</div>

