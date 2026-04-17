---
title: migrateTo()
description: "Migrates database to a specified version. Whilst you can use this in your application, the recommended useage is via either the CLI or the provided GUI interfac"
sidebar:
  label: migrateTo()
  order: 0
---

## Signature

`migrateTo()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

Migrates database to a specified version. Whilst you can use this in your application, the recommended useage is via either the CLI or the provided GUI interface



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `version` | `string` | no | — | The Database schema version to migrate to |

## Examples

<pre><code class='javascript'>// Migrate to a specific version
// Returns a message with the result
result=application.wheels.migrator.migrateTo(version);
</code></pre>
