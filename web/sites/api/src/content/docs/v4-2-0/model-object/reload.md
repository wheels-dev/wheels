---
title: reload()
description: "Reloads the property values of this object from the database."
sidebar:
  label: reload()
  order: 0
---

## Signature

`reload()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Reloads the property values of this object from the database.




## Examples

<pre><code class='javascript'>// 1. Reload after a call that may have changed values in the database
employee = model(&quot;Employee&quot;).findByKey(params.key);
employee.someCallThatChangesValuesInTheDatabase();
employee.reload();

// 2. Discard in-memory changes and restore the current database values
post = model(&quot;Post&quot;).findByKey(params.id);
post.title = &quot;Draft title that we want to discard&quot;;
post.reload();
// post.title now reflects the value stored in the database
</code></pre>
