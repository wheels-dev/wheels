---
title: migrateIndividual()
description: "Runs a single specific migration's up() regardless of sequence order."
sidebar:
  label: migrateIndividual()
  order: 0
---

## Signature

`migrateIndividual()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

Runs a single specific migration's up() regardless of sequence order.
Used for out-of-sequence migrations that were created by other developers
and need to be applied individually without affecting the current version pointer.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `version` | `string` | yes | — | The version number of the specific migration to run |

</div>

