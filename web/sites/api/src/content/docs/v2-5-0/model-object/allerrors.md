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


It does this by storing instances of models that are associations, and not checking associations of those instances because they have already been checked.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `includeAssociations` | `boolean` | no | `false` |  |
| `seenErrors` | `array` | no | `[runtime expression]` | is a private argument not meant to be used by the user, the function uses this to ensure circular dependency avoidance. |

## Examples

<pre><code class='javascript'>// Get all the errors for the `user` object.
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
</code></pre>
