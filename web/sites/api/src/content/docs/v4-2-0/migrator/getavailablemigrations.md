---
title: getAvailableMigrations()
description: "Searches db/migrate folder for migrations. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interfac"
sidebar:
  label: getAvailableMigrations()
  order: 0
---

## Signature

`getAvailableMigrations()` — returns `array`

**Available in:** `migrator`
**Category:** General Functions

## Description

Searches db/migrate folder for migrations. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface


$getVersionsPreviouslyMigrated). Callers that already hold the list
(doctor, info, migrateTo) pass it through to avoid re-running the
tracking-table probe chain; when empty it is computed here.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `path` | `string` | no | `[runtime expression]` | Path to Migration Files: defaults to /app/migrator/migrations/ |
| `previousMigrationList` | `string` | no | — | Optional precomputed applied-versions list (from |

</div>

## Examples

<pre><code class='javascript'>// 1. Get all available migrations and find the latest version
migrations = application.wheels.migrator.getAvailableMigrations();

if (arrayLen(migrations)) {
    latestVersion = migrations[arrayLen(migrations)].version;
} else {
    latestVersion = 0;
}

// 2. List pending (not yet run) migrations
migrations = application.wheels.migrator.getAvailableMigrations();

for (migration in migrations) {
    if (migration.status != &quot;migrated&quot;) {
        writeOutput(migration.version &amp; &quot; - &quot; &amp; migration.name);
    }
}

// 3. Use a custom migrations path
migrations = application.wheels.migrator.getAvailableMigrations(path=expandPath(&quot;/app/db/migrate/&quot;));
</code></pre>
