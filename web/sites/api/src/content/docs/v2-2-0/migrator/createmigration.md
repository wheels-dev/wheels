---
title: createMigration()
description: "Creates a migration file. Whilst you can use this in your application, the recommended useage is via either the CLI or the provided GUI interface"
sidebar:
  label: createMigration()
  order: 0
---

## Signature

`createMigration()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

Creates a migration file. Whilst you can use this in your application, the recommended useage is via either the CLI or the provided GUI interface



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `migrationName` | `string` | yes | — |  |
| `templateName` | `string` | no | — |  |
| `migrationPrefix` | `string` | no | `timestamp` |  |

## Examples

<pre><code class='javascript'>// Create an empty migration file
result=application.wheels.migrator.createMigration(&quot;MyMigrationFile&quot;);

// Or Create a migration file from the create-table template
result=application.wheels.migrator.createMigration(&quot;MyMigrationFile&quot;,&quot;create-table&quot;);
</code></pre>
