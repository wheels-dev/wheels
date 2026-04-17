---
title: getAvailableMigrations()
description: "The getAvailableMigrations() function scans the migration folder (by default /app/migrator/migrations/) and returns an array of all migration files it finds. Ea"
sidebar:
  label: getAvailableMigrations()
  order: 0
---

## Signature

`getAvailableMigrations()` — returns `array`

**Available in:** `migrator`
**Category:** General Functions

## Description

The getAvailableMigrations() function scans the migration folder (by default /app/migrator/migrations/) and returns an array of all migration files it finds. Each item in the array contains information about the migration, including its version. While this function can be called from within your application, it is primarily intended for use via the Wheels CLI or GUI tools. It is useful for programmatically determining which migrations are available and what the latest migration version is.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `path` | `string` | no | `[runtime expression]` | Path to Migration Files: defaults to /migrator/migrations/ |

## Examples

<pre><code class='javascript'>1. Get all available migrations in the default folder
migrations = application.wheels.migrator.getAvailableMigrations();

// Determine the latest migration version
if (ArrayLen(migrations)) {
    latestVersion = migrations[ArrayLen(migrations)].version;
} else {
    latestVersion = 0;
}

2. Get available migrations from a custom folder
customMigrations = application.wheels.migrator.getAvailableMigrations(path=&quot;/custom/migrations&quot;);

// Loop through migrations and display their versions
for (var m in migrations) {
    writeOutput(&quot;Migration version: &quot; & m.version & &quot;&lt;br&gt;&quot;);
}
</code></pre>
