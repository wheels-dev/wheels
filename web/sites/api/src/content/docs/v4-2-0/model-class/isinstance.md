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

<pre><code class='javascript'>// 1. Branch logic inside a shared model method based on class vs. instance context
function memberIsAdmin() {
	if (isInstance()) {
		// Called on an instance object — property is already loaded
		return this.admin;
	} else {
		// Called on the class — look up the record first
		return this.findByKey(arguments.id).admin;
	}
}

// 2. Use isInstance() in config() to guard instance-only setup
component extends=&quot;Model&quot; {
	function config() {
		if (isInstance()) {
			// Instance-specific initialization (rarely needed; shown for contrast)
		} else {
			// Class-level configuration: validations, associations, callbacks
			validatesPresenceOf(properties=&quot;username,email&quot;);
			hasMany(name=&quot;posts&quot;);
		}
	}
}

// 3. Pair with isClass() to make the intent explicit
function label() {
	if (isClass()) {
		return &quot;User (class)&quot;;
	}
	return &quot;User #this.id#&quot;;
}
</code></pre>
