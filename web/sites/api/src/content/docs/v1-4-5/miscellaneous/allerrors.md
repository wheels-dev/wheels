---
title: allErrors()
description: "Returns an array of all the errors on the object."
sidebar:
  label: allErrors()
  order: 0
---

## Signature

`allErrors()` — returns `any`




## Description

Returns an array of all the errors on the object.


## Examples

<pre>allErrors() &lt;!--- Get all the errors for the `user` object ---&gt;
&lt;cfset errorInfo = user.allErrors()&gt; &lt;!--- Sample Return of Function ---&gt;
[
	{
  	message:'Username must not be blank',
    name:'usernameError',
    property:'username'
  },
  {
  	message:'Password must not be blank',
    name:'passwordError',
    property:'password'
  }
]</pre>
