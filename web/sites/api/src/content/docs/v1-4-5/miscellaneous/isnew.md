---
title: isNew()
description: "Returns true if this object hasn't been saved yet. (In other words, no matching record exists in the database yet.) Returns false if a record exists."
sidebar:
  label: isNew()
  order: 0
---

## Signature

`isNew()` — returns `any`




## Description

Returns true if this object hasn't been saved yet. (In other words, no matching record exists in the database yet.) Returns false if a record exists.


## Examples

<pre>isNew() &lt;!--- Create a new object and then check if it is new (yes, this example is ridiculous. It makes more sense in the context of callbacks for example) ---&gt;
&lt;cfset employee = model(&quot;employee&quot;).new()&gt;
&lt;cfif employee.isNew()&gt;
    &lt;!--- Do something... ---&gt;
&lt;/cfif&gt;</pre>
