---
title: clearErrors()
description: "Clears out all errors set on the object or only the ones set for a specific property or name."
sidebar:
  label: clearErrors()
  order: 0
---

## Signature

`clearErrors()` — returns `void`

**Available in:** `model`
**Category:** Error Functions

## Description

Clears out all errors set on the object or only the ones set for a specific property or name.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Specify a property name here if you want to clear all errors set on that property. |
| `name` | `string` | no | — | Specify an error name here if you want to clear all errors set with that error name. |

</div>

## Examples

<pre><code class='javascript'>// 1. Clear all errors on the object
this.clearErrors();

// 2. Clear all errors set on the `firstName` property
this.clearErrors(property=&quot;firstName&quot;);

// 3. Clear only errors that were set with a specific error name
this.clearErrors(name=&quot;invalidFormat&quot;);

// 4. Clear errors on a specific property that were also set with a specific name
this.clearErrors(property=&quot;email&quot;, name=&quot;duplicateEmail&quot;);
</code></pre>
