---
title: migrateToLatest()
description: "Migrates the database schema to the latest available migration version. This is a shortcut for migrateTo(version) without needing to specify a version explicitl"
sidebar:
  label: migrateToLatest()
  order: 0
---

## Signature

`migrateToLatest()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

Migrates the database schema to the latest available migration version. This is a shortcut for migrateTo(version) without needing to specify a version explicitly.




## Examples

<pre><code class='javascript'>// Migrate database to the latest version
result = application.wheels.migrator.migrateToLatest();

// Output the result message
writeOutput(result);</code></pre>
