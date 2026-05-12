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

<pre><code class='javascript'>// Disable automatic validations (for example when automatic validations are enabled globally, but we want to disable just for this model).
config() {
	automaticValidations(false);
}
</code></pre>
