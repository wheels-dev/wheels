---
title: automaticValidations()
description: "Whether or not to enable default validations for this model."
sidebar:
  label: automaticValidations()
  order: 0
---

## Signature

`automaticValidations()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Whether or not to enable default validations for this model.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `value` | `boolean` | yes | — | Set to `true` or `false`. |

</div>

## Examples

<pre><code class='javascript'>// 1. Disable automatic validations for this model (useful when automatic validations are enabled globally but you want to opt out for a specific model).
component extends=&quot;Model&quot; {
	function config() {
		automaticValidations(false);
	}
}

// 2. Explicitly enable automatic validations for this model (useful when automatic validations are disabled globally but you want to opt in for a specific model).
component extends=&quot;Model&quot; {
	function config() {
		automaticValidations(true);
	}
}
</code></pre>
