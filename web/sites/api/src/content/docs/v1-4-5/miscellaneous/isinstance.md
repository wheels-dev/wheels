---
title: isInstance()
description: "Use this method to check whether you are currently in an instance object."
sidebar:
  label: isInstance()
  order: 0
---

## Signature

`isInstance()` — returns `any`




## Description

Use this method to check whether you are currently in an instance object.


## Examples

<pre>isInstance() &lt;!--- Use the passed in `id` when we're not already in an instance ---&gt;
&lt;cffunction name=&quot;memberIsAdmin&quot;&gt;
    &lt;cfif isInstance()&gt;
        &lt;cfreturn this.admin&gt;
    &lt;cfelse&gt;
        &lt;cfreturn this.findByKey(arguments.id).admin&gt;
    &lt;/cfif&gt;
&lt;/cffunction&gt;</pre>
