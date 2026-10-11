---
title: afterValidationOnCreate()
description: "Registers method(s) that should be called after a new object is validated."
sidebar:
  label: afterValidationOnCreate()
  order: 0
---

## Signature

`afterValidationOnCreate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called after a new object is validated.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Call a single method after a new object is validated on create
component extends=&quot;Model&quot; {
	function config() {
		afterValidationOnCreate(&quot;assignDefaults&quot;);
	}

	private function assignDefaults() {
		if (!Len(this.role)) {
			this.role = &quot;member&quot;;
		}
	}
}

// 2. Call multiple methods after validation on create (comma-delimited list)
component extends=&quot;Model&quot; {
	function config() {
		afterValidationOnCreate(&quot;sanitizeFields,logNewRecord&quot;);
	}
}

// 3. Use the singular `method` alias for clarity
component extends=&quot;Model&quot; {
	function config() {
		afterValidationOnCreate(method=&quot;trimWhitespace&quot;);
	}
}
</code></pre>
