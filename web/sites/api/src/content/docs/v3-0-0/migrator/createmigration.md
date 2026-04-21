---
title: createMigration()
description: "The createMigration() method is used to generate a new migration file for managing database schema changes. While you can call it from your application code, it"
sidebar:
  label: createMigration()
  order: 0
---

## Signature

`createMigration()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

The createMigration() method is used to generate a new migration file for managing database schema changes. While you can call it from your application code, it is primarily intended for use via the CLI or Wheels GUI. A migration file allows you to define table creations, modifications, or deletions in a structured way that can be applied or rolled back consistently.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `migrationName` | `string` | yes | — |  |
| `templateName` | `string` | no | — |  |
| `migrationPrefix` | `string` | no | `timestamp` |  |

</div>

## Examples

<pre><code class='javascript'>1. Create an empty migration file:

result = application.wheels.migrator.createMigration("MyMigrationFile");

// Generates a blank migration file with a timestamped prefix.

// You can then edit it to define your table or schema changes.

2. Create a migration file from a template (e.g., create-table):

result = application.wheels.migrator.createMigration("MyMigrationFile", "create-table");

// Generates a migration file pre-populated with a create-table template.</code></pre>
