---
title: processAction()
description: "Process the specified action of the controller."
sidebar:
  label: processAction()
  order: 0
---

## Signature

`processAction()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Process the specified action of the controller.
This is exposed in the API primarily for testing purposes; you would not usually call it directly unless in the test suite.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `includeFilters` | `string` | no | `true` | Set to `before` to only execute "before" filters, `after` to only execute "after" filters or `false` to skip all filters. This argument is generally inherited from the `processRequest` function during unit test execution. |

</div>

