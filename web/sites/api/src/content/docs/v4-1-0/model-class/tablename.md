---
title: tableName()
description: "Returns the name of the database table that this model is mapped to."
sidebar:
  label: tableName()
  order: 0
---

## Signature

`tableName()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns the name of the database table that this model is mapped to.
This is a getter and takes no arguments — the table setter is <code>table()</code>.
Calling <code>tableName()</code> with an argument has always been a silent no-op (CFML
accepts the extra argument and the model keeps its convention table), a trap
some 4.0-era docs taught as a setter. When error information is shown
(development / testing — the same gate <code>exists()</code> uses above) it now fails
loud; in production it stays a no-op so an upgrade never breaks a running
app. See issue #3079.




## Examples

<pre><code class='javascript'>// 1. Check what table the User model is mapped to (Wheels convention: singular model -&gt; plural table)
name = model(&quot;User&quot;).tableName();
// name -&gt; &quot;users&quot;

// 2. Check the table for a model that uses a custom table name (set via table() in config())
// In models/StaffMember.cfc: table(&quot;employees&quot;);
name = model(&quot;StaffMember&quot;).tableName();
// name -&gt; &quot;employees&quot;

// 3. Use the table name dynamically in a log message or custom SQL fragment
tableUsed = model(&quot;Order&quot;).tableName();
writeOutput(&quot;Querying table: &quot; &amp; tableUsed);
// Outputs: Querying table: orders
</code></pre>
