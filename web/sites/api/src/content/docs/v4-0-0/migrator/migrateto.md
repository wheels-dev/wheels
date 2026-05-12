---
title: migrateTo()
description: "Migrates database to a specified version. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface"
sidebar:
  label: migrateTo()
  order: 0
---

## Signature

`migrateTo()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

Migrates database to a specified version. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `version` | `string` | no | — | The Database schema version to migrate to |
| `missingMigFlag` | `boolean` | no | `false` | Flag for any available missing migrations |

</div>

