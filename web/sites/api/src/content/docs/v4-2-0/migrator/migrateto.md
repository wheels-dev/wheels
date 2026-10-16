---
title: migrateTo()
description: "Migrates database to a specified version. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface"
sidebar:
  label: migrateTo()
  order: 0
---

## Signature

`migrateTo()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

Migrates database to a specified version. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `version` | `string` | no | — | The Database schema version to migrate to |
| `missingMigFlag` | `boolean` | no | `false` | Flag for any available missing migrations |

</div>

## Examples

<pre><code class='javascript'>// 1. Migrate up to a specific version
result = application.wheels.migrator.migrateTo(&quot;20240315120000&quot;);
// result -&gt; &quot;Migrating from 20231201000000 up to 20240315120000.
// -------- 20240315120000_add_status_to_orders --------------------
// &quot;

// 2. Migrate down to an earlier version (rolls back newer migrations)
result = application.wheels.migrator.migrateTo(&quot;20230601000000&quot;);
// result -&gt; &quot;Migrating from 20240315120000 down to 20230601000000.
// ------- 20240315120000_add_status_to_orders ---------------------
// &quot;

// 3. Migrate to version 0 (rolls back all migrations)
result = application.wheels.migrator.migrateTo(&quot;0&quot;);
// result -&gt; &quot;Migrating from 20240315120000 down to 0.
// ...&quot;

// 4. Check the result string for errors before proceeding
result = application.wheels.migrator.migrateTo(&quot;20240315120000&quot;);
if (FindNoCase(&quot;Error&quot;, result)) {
    writeOutput(&quot;Migration failed: &quot; &amp; result);
} else {
    writeOutput(&quot;Migration result: &quot; &amp; result);
}

// 5. Apply a missing (out-of-order gap) migration using missingMigFlag
// Use this when a migration with a timestamp earlier than the current version
// was never applied in your environment.
result = application.wheels.migrator.migrateTo(
    version = &quot;20231205083000&quot;,
    missingMigFlag = true
);
writeOutput(result);
</code></pre>
