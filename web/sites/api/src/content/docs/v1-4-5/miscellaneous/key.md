---
title: key()
description: "Returns the value of the primary key for the object. If you have a single primary key named id, then someObject.key() is functionally equivalent to someObject.i"
sidebar:
  label: key()
  order: 0
---

## Signature

`key()` — returns `any`




## Description

Returns the value of the primary key for the object. If you have a single primary key named id, then someObject.key() is functionally equivalent to someObject.id. This method is more useful when you do dynamic programming and don't know the name of the primary key or when you use composite keys (in which case it's convenient to use this method to get a list of both key values returned).


## Examples

<pre>key() &lt;!--- Get an object and then get the primary key value(s) ---&gt;
&lt;cfset employee = model(&quot;employee&quot;).findByKey(params.key)&gt;
&lt;cfset val = employee.key()&gt;</pre>
