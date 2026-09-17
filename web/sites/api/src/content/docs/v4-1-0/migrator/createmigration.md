---
title: createMigration()
description: "Creates a migration file. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface"
sidebar:
  label: createMigration()
  order: 0
---

## Signature

`createMigration()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

Creates a migration file. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `migrationName` | `string` | yes | — |  |
| `templateName` | `string` | no | — |  |
| `migrationPrefix` | `string` | no | `timestamp` |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Create a blank migration file (uses timestamp prefix by default)
result = application.wheels.migrator.createMigration(&quot;CreateUsersTable&quot;);
// result -&gt; &quot;The migration 20240815123045_CreateUsersTable.cfc file was created&quot;

// 2. Create a migration from a built-in template (e.g. create-table)
result = application.wheels.migrator.createMigration(
	migrationName=&quot;CreatePostsTable&quot;,
	templateName=&quot;create-table&quot;
);

// 3. Create a migration using a sequential numeric prefix instead of a timestamp
result = application.wheels.migrator.createMigration(
	migrationName=&quot;AddIndexToUsers&quot;,
	migrationPrefix=&quot;numeric&quot;
);
// result -&gt; &quot;The migration 001_AddIndexToUsers.cfc file was created&quot;
</code></pre>
