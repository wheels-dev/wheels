---
title: redoMigration()
description: "Reruns the specified migration version. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface"
sidebar:
  label: redoMigration()
  order: 0
---

## Signature

`redoMigration()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

Reruns the specified migration version. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `version` | `string` | no | — | The Database schema version to rerun |

</div>

## Examples

<pre><code class='javascript'>// 1. Redo the current (most recent) migration — rolls it back then re-applies it
result = application.wheels.migrator.redoMigration();
// result -&gt; &quot;
// ------- 20240315120000_add_status_to_orders ----------------------
// &quot;

// 2. Redo a specific migration version
result = application.wheels.migrator.redoMigration(version=&quot;20240101000000&quot;);
// result -&gt; &quot;
// ------- 20240101000000_create_users ------------------------------
// &quot;

// 3. Check for errors after redoing a migration
result = application.wheels.migrator.redoMigration(version=&quot;20240315120000&quot;);
if (FindNoCase(&quot;Error&quot;, result)) {
    writeOutput(&quot;Redo failed: &quot; &amp; result);
} else {
    writeOutput(&quot;Migration redone successfully.&quot;);
}
</code></pre>
