---
title: getAvailableMigrations()
description: "Searches db/migrate folder for migrations. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interfac"
sidebar:
  label: getAvailableMigrations()
  order: 0
---

## Signature

`getAvailableMigrations()` — returns `array`

**Available in:** `migrator`
**Category:** General Functions

## Description

Searches db/migrate folder for migrations. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `path` | `string` | no | `[runtime expression]` | Path to Migration Files: defaults to /app/migrator/migrations/ |

</div>

