---
title: pretendVersion()
description: "Records a version as applied in <code>wheels_migrator_versions</code> without"
sidebar:
  label: pretendVersion()
  order: 0
---

## Signature

`pretendVersion()` — returns `struct`

**Available in:** `migrator`
**Category:** General Functions

## Description

Records a version as applied in <code>wheels_migrator_versions</code> without
running its up() method. Useful when a peer applied the migration
via direct SQL or a different tool and you need the tracking
table to reflect that. Refuses if the version is already applied,
or if no local file matches (only known versions can be pretended).
Returns: {success, recorded, message}



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `version` | `string` | yes | — | The version string to record (digits only after sanitisation). |

</div>

