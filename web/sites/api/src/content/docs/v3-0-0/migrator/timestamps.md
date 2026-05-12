---
title: timestamps()
description: "Shortcut for adding Wheels’ convention-based automatic timestamp and soft delete columns to a table definition during migrations. Instead of defining each field"
sidebar:
  label: timestamps()
  order: 0
---

## Signature

`timestamps()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Shortcut for adding Wheels’ convention-based automatic timestamp and soft delete columns to a table definition during migrations. Instead of defining each field manually, this function quickly sets up the standard fields that are commonly used across models to track record lifecycle and soft deletion. By default, it adds createdAt, updatedAt, and deletedAt columns with appropriate types, making your migrations more concise and consistent. Only available in a migrator CFC.




## Examples

<pre><code class='javascript'>1. Add createdAt, updatedAt, and deletedAt columns to the users table
t.timestamps()</code></pre>
