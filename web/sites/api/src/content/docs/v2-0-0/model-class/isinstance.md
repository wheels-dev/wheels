---
title: isInstance()
description: "Use this method to check whether you are currently in an instance object."
sidebar:
  label: isInstance()
  order: 0
---

## Signature

`isInstance()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Use this method to check whether you are currently in an instance object.




## Examples

<pre>// Use the passed in `id` when we're not already in an instance
function memberIsAdmin(){
	if(isInstance()){
		return this.admin;
	} else {
		return this.findByKey(arguments.id).admin;
	}
}
</pre>
