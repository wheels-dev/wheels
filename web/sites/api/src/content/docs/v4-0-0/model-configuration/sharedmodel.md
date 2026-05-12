---
title: sharedModel()
description: "Marks this model as shared — it will always use the default application datasource"
sidebar:
  label: sharedModel()
  order: 0
---

## Signature

`sharedModel()` — returns `void`

**Available in:** `model`
**Category:** Multi-Tenancy

## Description

Marks this model as shared — it will always use the default application datasource
even when a tenant is active. Use this for models like <code>Tenant</code>, <code>Plan</code>, or any
lookup table that lives in the central database rather than per-tenant databases.




