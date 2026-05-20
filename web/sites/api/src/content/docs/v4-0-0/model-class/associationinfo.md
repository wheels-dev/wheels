---
title: associationInfo()
description: "Returns a struct containing all association definitions for this model."
sidebar:
  label: associationInfo()
  order: 0
---

## Signature

`associationInfo()` — returns `struct`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a struct containing all association definitions for this model.
Each key is the association name, and the value is a struct with association metadata
including <code>type</code> (belongsTo, hasMany, hasOne), <code>modelName</code>, <code>foreignKey</code>, <code>joinKey</code>, and <code>dependent</code>.




