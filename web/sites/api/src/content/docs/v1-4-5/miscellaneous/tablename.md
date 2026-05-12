---
title: tableName()
description: "Returns the name of the database table that this model is mapped to."
sidebar:
  label: tableName()
  order: 0
---

## Signature

`tableName()` — returns `any`




## Description

Returns the name of the database table that this model is mapped to.


## Examples

<pre>tableName() &lt;!--- Check what table the user model uses ---&gt;
&lt;cfset whatAmIMappedTo = model(&quot;user&quot;).tableName()&gt;</pre>
