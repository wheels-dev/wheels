---
title: forgetVersion()
description: "Removes a row from <code>wheels_migrator_versions</code> without running"
sidebar:
  label: forgetVersion()
  order: 0
---

## Signature

`forgetVersion()` — returns `struct`

**Available in:** `migrator`
**Category:** General Functions

## Description

Removes a row from <code>wheels_migrator_versions</code> without running
down(). Only orphan versions (those with no matching local file)
can be forgotten — for legitimate rollbacks, use <code>migrate down</code>.
Returns: {success, removed, message}



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `version` | `string` | yes | — | The version string to forget (digits only after sanitisation). |

</div>

