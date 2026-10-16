---
title: migrateIndividual()
description: "Runs a single specific migration's up() regardless of sequence order."
sidebar:
  label: migrateIndividual()
  order: 0
---

## Signature

`migrateIndividual()` — returns `string`

**Available in:** `migrator`
**Category:** General Functions

## Description

Runs a single specific migration's up() regardless of sequence order.
Used for out-of-sequence migrations that were created by other developers
and need to be applied individually without affecting the current version pointer.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `version` | `string` | yes | — | The version number of the specific migration to run |

</div>

## Examples

<pre><code class='javascript'>// 1. Run a specific migration by version number (out-of-sequence)
result = application.wheels.migrator.migrateIndividual(&quot;20240315120000&quot;);
// result -&gt; &quot;Running individual migration 20240315120000.
// -------- 20240315120000_add_status_to_orders --------------------
// &quot;

// 2. Check the result string for errors or success messages
result = application.wheels.migrator.migrateIndividual(&quot;20240101000000&quot;);
if (FindNoCase(&quot;Error&quot;, result)) {
    writeOutput(&quot;Migration failed: &quot; &amp; result);
} else if (FindNoCase(&quot;already been applied&quot;, result)) {
    writeOutput(&quot;Skipped: migration was already applied.&quot;);
} else {
    writeOutput(&quot;Migration applied successfully.&quot;);
}

// 3. Apply an individual colleague's migration without advancing the version pointer
// This is useful when a team member's migration has a lower timestamp than
// the current version but was not yet applied in your environment.
colVersion = &quot;20231205083000&quot;;
result = application.wheels.migrator.migrateIndividual(colVersion);
writeOutput(result);
</code></pre>
