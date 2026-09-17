---
title: errorsOn()
description: "Returns an array of all errors associated with the supplied property (and error name if passed in)."
sidebar:
  label: errorsOn()
  order: 0
---

## Signature

`errorsOn()` — returns `array`

**Available in:** `model`
**Category:** Error Functions

## Description

Returns an array of all errors associated with the supplied property (and error name if passed in).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Specify the property name to return errors for here. |
| `name` | `string` | no | — | If you want to return only errors on the property set with a specific error name you can specify it here. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get all errors associated with the emailAddress property
errors = user.errorsOn(&quot;emailAddress&quot;);
// errors -&gt; [{property: &quot;emailAddress&quot;, message: &quot;is invalid&quot;, name: &quot;&quot;}, ...]

// 2. Get only errors on emailAddress that were set with a specific error name
errors = user.errorsOn(property=&quot;emailAddress&quot;, name=&quot;formatCheck&quot;);
// errors -&gt; [{property: &quot;emailAddress&quot;, message: &quot;must be a valid email&quot;, name: &quot;formatCheck&quot;}]

// 3. Check errors on a property and loop over them
errors = user.errorsOn(&quot;username&quot;);
for (error in errors) {
    writeOutput(error.message);
}
</code></pre>
