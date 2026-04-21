---
title: redoMigration()
description: "Allows you to rerun a specific database migration version. This can be useful for testing migrations, correcting issues in a migration, or resetting a schema ch"
sidebar:
  label: redoMigration()
  order: 0
---

## Signature

`redoMigration()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

Allows you to rerun a specific database migration version. This can be useful for testing migrations, correcting issues in a migration, or resetting a schema change during development. While it can be called directly from your application code, it is generally recommended to use this function via the CommandBox CLI or the Wheels GUI migration interface, as these provide safer execution and logging.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `version` | `string` | no | — | The Database schema version to rerun |

</div>

## Examples

<pre><code class='javascript'>1. Rerun a specific migration version
result = redoMigration(version=&quot;202509250915&quot;);
writeOutput(result); // Returns status or log of the migration rerun

2. Using redoMigration in a script for testing
if (environment() == &quot;development&quot;) {
    redoMigration(version=&quot;202509250920&quot;);
}

3. Rerun latest migration (if version not specified)
result = redoMigration();
writeOutput(result);
</code></pre>
