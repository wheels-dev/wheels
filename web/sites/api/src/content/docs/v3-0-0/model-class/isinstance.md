---
title: isInstance()
description: "Checks whether the current context is an instance of a model object rather than a class-level context. This is useful when a method could be called either on a"
sidebar:
  label: isInstance()
  order: 0
---

## Signature

`isInstance()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Checks whether the current context is an instance of a model object rather than a class-level context. This is useful when a method could be called either on a class or an instance, and you want to behave differently depending on which it is.




## Examples

<pre><code class='javascript'>1. Use the passed in `id` when we're not already in an instance
function memberIsAdmin(){
	if(isInstance()){
		return this.admin;
	} else {
		return this.findByKey(arguments.id).admin;
	}
}
</code></pre>
