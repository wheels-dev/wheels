---
title: generateUUID()
description: "Generates a 36-character UUID compatible with SQL Server's uniqueidentifier."
sidebar:
  label: generateUUID()
  order: 0
---

## Signature

`generateUUID()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** UUID Functions

## Description

Generates a 36-character UUID compatible with SQL Server's uniqueidentifier.




## Examples

<pre><code class='javascript'>// 1. Generate a UUID and store it in a variable
newId = generateUUID();
// newId -&gt; &quot;550e8400-e29b-41d4-a716-446655440000&quot; (36-character UUID)

// 2. Use generateUUID() to assign a unique identifier before saving a record
post = model(&quot;Post&quot;).new(title=&quot;Hello World&quot;);
post.externalId = generateUUID();
post.save();

// 3. Generate a UUID compatible with SQL Server's uniqueidentifier column
// Useful when inserting records that need a GUID primary key
token = generateUUID();
// token -&gt; &quot;a1b2c3d4-e5f6-7890-abcd-ef1234567890&quot;
</code></pre>
