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

<pre><code class='javascript'>1. Check an older object
employee = model(&quot;employee&quot;).findByKey(123);
if (employee.isPersisted()) {
    writeOutput(&quot;This employee exists in the database.&quot;);
} else {
    writeOutput(&quot;This employee has not been saved yet.&quot;);
}

2. Creating a new object
newEmployee = model(&quot;employee&quot;).new();
if (!newEmployee.isPersisted()) {
    writeOutput(&quot;This is a new object, not yet persisted.&quot;);
}</code></pre>
