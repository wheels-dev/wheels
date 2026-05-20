---
title: validationInfo()
description: "Returns a struct containing all validation rules for this model, keyed by trigger (<code>onSave</code>, <code>onCreate</code>, <code>onUpdate</code>)."
sidebar:
  label: validationInfo()
  order: 0
---

## Signature

`validationInfo()` — returns `struct`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a struct containing all validation rules for this model, keyed by trigger (<code>onSave</code>, <code>onCreate</code>, <code>onUpdate</code>).
Each trigger contains an array of validation rule structs with <code>method</code>, <code>properties</code>, <code>message</code>, and other parameters.




