---
title: isClass()
description: "Use this method to check whether you are currently in a class-level object."
sidebar:
  label: isClass()
  order: 0
---

## Signature

`isClass()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Use this method to check whether you are currently in a class-level object.




## Examples

<pre><code class='javascript'>// Use the passed in `id` when we're already in an instance
function memberIsAdmin(){
	if(isClass()){
		return this.findByKey(arguments.id).admin;
	} else {
		return this.admin;
	}
}
</code></pre>
