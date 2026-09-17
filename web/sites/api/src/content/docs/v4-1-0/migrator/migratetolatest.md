---
title: migrateToLatest()
description: "Shortcut function to migrate to the latest version"
sidebar:
  label: migrateToLatest()
  order: 0
---

## Signature

`migrateToLatest()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

Shortcut function to migrate to the latest version




## Examples

<pre><code class='javascript'>// 1. Run all pending migrations to bring the database up to the latest version
result = application.wheels.migrator.migrateToLatest();
// result -&gt; &quot;Migrating from 20240101000000 up to 20240315120000.
// -------- 20240315120000_add_status_to_orders --------------------
// &quot;

// 2. Already at the latest version — no migration required
result = application.wheels.migrator.migrateToLatest();
// result -&gt; &quot;Database is currently at version 20240315120000. No migration required.&quot;

// 3. Check for errors after migrating to latest
result = application.wheels.migrator.migrateToLatest();
if (FindNoCase(&quot;Error&quot;, result)) {
    writeOutput(&quot;Migration failed: &quot; &amp; result);
} else {
    writeOutput(&quot;All migrations applied successfully.&quot;);
}
</code></pre>
