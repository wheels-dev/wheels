---
title: isPersisted()
description: "Returns <code>true</code> if this object has been persisted to the database or was loaded from the database via a finder."
sidebar:
  label: isPersisted()
  order: 0
---

## Signature

`isPersisted()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns <code>true</code> if this object has been persisted to the database or was loaded from the database via a finder.
Returns <code>false</code> if the record has not been persisted to the database.




## Examples

<pre><code class='javascript'>// 1. Check if a newly created (unsaved) object has been persisted
user = model(&quot;User&quot;).new(firstName=&quot;Jane&quot;, lastName=&quot;Doe&quot;);
writeOutput(user.isPersisted()); // -&gt; false

// 2. Check if an object loaded from the database is persisted
user = model(&quot;User&quot;).findByKey(1);
writeOutput(user.isPersisted()); // -&gt; true

// 3. Check persistence after saving a new object
post = model(&quot;Post&quot;).new(title=&quot;Hello World&quot;, body=&quot;First post.&quot;);
post.save();
writeOutput(post.isPersisted()); // -&gt; true
</code></pre>
