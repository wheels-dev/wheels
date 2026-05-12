---
title: isNew()
description: "Returns <code>true</code> if this object hasn't been saved yet (in other words, no matching record exists in the database yet)."
sidebar:
  label: isNew()
  order: 0
---

## Signature

`isNew()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns <code>true</code> if this object hasn't been saved yet (in other words, no matching record exists in the database yet).
Returns <code>false</code> if a record exists.




## Examples

<pre>// Create a new object and then check if it is new (yes, this example is ridiculous. It makes more sense in the context of callbacks for example)
employee = model(&quot;employee&quot;).new()&gt;
&lt;cfif employee.isNew()&gt;
    // Do something...
&lt;/cfif&gt;</pre>
