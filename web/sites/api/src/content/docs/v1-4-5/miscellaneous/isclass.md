---
title: isClass()
description: "Use this method within a model's method to check whether you are currently in a class-level object."
sidebar:
  label: isClass()
  order: 0
---

## Signature

`isClass()` — returns `any`




## Description

Use this method within a model's method to check whether you are currently in a class-level object.


## Examples

<pre>isClass() &lt;!--- Use the passed in `id` when we're already in an instance ---&gt;
&lt;cffunction name=&quot;memberIsAdmin&quot;&gt;
    &lt;cfif isClass()&gt;
        &lt;cfreturn this.findByKey(arguments.id).admin&gt;
    &lt;cfelse&gt;
        &lt;cfreturn this.admin&gt;
    &lt;/cfif&gt;
&lt;/cffunction&gt;</pre>
