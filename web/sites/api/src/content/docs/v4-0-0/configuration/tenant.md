---
title: tenant()
description: "Returns the current tenant struct, or an empty struct if no tenant is active."
sidebar:
  label: tenant()
  order: 0
---

## Signature

`tenant()` — returns `struct`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Multi-Tenancy

## Description

Returns the current tenant struct, or an empty struct if no tenant is active.
The tenant struct contains: <code>id</code>, <code>dataSource</code>, <code>config</code>, and <code>$locked</code>.




