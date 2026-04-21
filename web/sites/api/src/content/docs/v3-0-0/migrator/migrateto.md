---
title: migrateTo()
description: "Migrates the database schema to a specified version. This function is primarily intended for programmatic database migrations, but the recommended usage is via"
sidebar:
  label: migrateTo()
  order: 0
---

## Signature

`migrateTo()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

Migrates the database schema to a specified version. This function is primarily intended for programmatic database migrations, but the recommended usage is via the CLI or Wheels GUI interface.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `version` | `string` | no | — | The Database schema version to migrate to |

</div>

## Examples

<pre><code class='javascript'>// Migrate to a specific version
// Returns a message with the result
result=application.wheels.migrator.migrateTo(version);
</code></pre>
