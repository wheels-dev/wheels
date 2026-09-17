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

<pre><code class='javascript'>// 1. Use isClass() to branch between class-level and instance-level behavior
// In a model method, detect whether the method is being called on the class
// (e.g. model(&quot;User&quot;).isAdmin(42)) or on an instance (e.g. user.isAdmin()).
function isAdmin(numeric id) {
	if (isClass()) {
		// Called on the class — look up the record by the provided id
		return this.findByKey(arguments.id).admin;
	} else {
		// Called on an instance — the property is already available
		return this.admin;
	}
}

// 2. Guard a class-only operation
function resetAllPasswords() {
	if (!isClass()) {
		Throw(type=&quot;App.Error&quot;, message=&quot;resetAllPasswords must be called on the class, not an instance.&quot;);
	}
	this.updateAll(password=&quot;changeme&quot;);
}
</code></pre>
