---
title: getCurrentMigrationVersion()
description: "The getCurrentMigrationVersion() function returns the version number of the latest migration that has been applied to the database. This is useful for determini"
sidebar:
  label: getCurrentMigrationVersion()
  order: 0
---

## Signature

`getCurrentMigrationVersion()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

The getCurrentMigrationVersion() function returns the version number of the latest migration that has been applied to the database. This is useful for determining the current schema state programmatically, though it is primarily intended for use via the Wheels CLI or GUI interface. You can use this function within your application to perform conditional logic based on the database version or to verify that the database is up-to-date.




## Examples

<pre><code class='javascript'>1. Get the current database migration version
currentVersion = application.wheels.migrator.getCurrentMigrationVersion();
writeOutput(&quot;Current DB version: &quot; & currentVersion);

// Compare with the latest available migration version
migrations = application.wheels.migrator.getAvailableMigrations();
if (ArrayLen(migrations)) {
    latestVersion = migrations[ArrayLen(migrations)].version;
    if (currentVersion LT latestVersion) {
        writeOutput(&quot;Database is behind the latest migration.&quot;);
    } else {
        writeOutput(&quot;Database is up-to-date.&quot;);
    }
}

// Conditional logic based on migration version
if (currentVersion EQ &quot;2023091501&quot;) {
    // perform tasks specific to this version
}
</code></pre>
