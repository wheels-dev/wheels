---
title: isClass()
description: "Determines whether the method is being called at the class level (on the model itself) or on an instance of the model. This is useful when the same function can"
sidebar:
  label: isClass()
  order: 0
---

## Signature

`isClass()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Determines whether the method is being called at the class level (on the model itself) or on an instance of the model. This is useful when the same function can be invoked either on a model object or directly on the model class.




## Examples

<pre><code class='javascript'>1. Use the passed in `id` when we're already in an instance
function memberIsAdmin(){
	if(isClass()){
		return this.findByKey(arguments.id).admin;
	} else {
		return this.admin;
	}
}
</code></pre>
