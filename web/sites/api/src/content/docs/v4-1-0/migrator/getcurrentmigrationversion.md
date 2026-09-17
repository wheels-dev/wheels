---
title: getCurrentMigrationVersion()
description: "Returns current database version. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface"
sidebar:
  label: getCurrentMigrationVersion()
  order: 0
---

## Signature

`getCurrentMigrationVersion()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

Returns current database version. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface




## Examples

<pre><code class='javascript'>// 1. Get current database version
currentVersion = application.wheels.migrator.getCurrentMigrationVersion();
// currentVersion -&gt; &quot;20240315120000&quot;  (timestamp-style version string, or &quot;0&quot; if no migrations have run)

// 2. Display version status in a maintenance view
currentVersion = application.wheels.migrator.getCurrentMigrationVersion();
if (currentVersion == &quot;0&quot;) {
    writeOutput(&quot;No migrations have been applied yet.&quot;);
} else {
    writeOutput(&quot;Database is at version: &quot; &amp; currentVersion);
}
</code></pre>
