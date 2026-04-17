---
title: debug()
description: "Used to examine an expression"
sidebar:
  label: debug()
  order: 0
---

## Signature

`debug()` — returns `any`

**Available in:** `test`
**Category:** Testing Functions

## Description

Used to examine an expression
Any overloaded arguments get passed to cfdump's attributeCollection



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `expression` | `string` | yes | — | The expression to examine |
| `display` | `boolean` | no | `true` | Whether to display the debug call. False returns without outputting anything into the buffer. Good when you want to leave the debug command in the test for later purposes, but don't want it to display |

