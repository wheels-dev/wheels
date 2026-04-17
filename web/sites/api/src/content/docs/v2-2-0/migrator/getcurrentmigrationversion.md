---
title: getCurrentMigrationVersion()
description: "Returns current database version. Whilst you can use this in your application, the recommended useage is via either the CLI or the provided GUI interface"
sidebar:
  label: getCurrentMigrationVersion()
  order: 0
---

## Signature

`getCurrentMigrationVersion()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

Returns current database version. Whilst you can use this in your application, the recommended useage is via either the CLI or the provided GUI interface




## Examples

<pre><code class='javascript'>// Get current database version
currentVersion = application.wheels.migrator.getCurrentMigrationVersion();
</code></pre>
