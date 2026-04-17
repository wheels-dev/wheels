---
title: allErrors()
description: "Returns an array of all the errors on the object."
sidebar:
  label: allErrors()
  order: 0
---

## Signature

`allErrors()` — returns `array`

**Available in:** `model`
**Category:** Error Functions

## Description

Returns an array of all the errors on the object.




## Examples

<pre>// Get all the errors for the `user` object.
errorInfo = user.allErrors();

// Sample return of method.
[
	{
  	message: 'Username must not be blank.',
    name: 'usernameError',
    property: 'username'
  },
  {
  	message: 'Password must not be blank.',
    name: 'passwordError',
    property: 'password'
  }
]
</pre>
