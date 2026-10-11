---
title: errorsOnBase()
description: "Returns an array of all errors associated with the object as a whole (not related to any specific property)."
sidebar:
  label: errorsOnBase()
  order: 0
---

## Signature

`errorsOnBase()` — returns `array`

**Available in:** `model`
**Category:** Error Functions

## Description

Returns an array of all errors associated with the object as a whole (not related to any specific property).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | — | Specify an error name here to only return errors for that error name. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get all general (base) errors for a model object after validation
user = model(&quot;User&quot;).new(params.user);
user.valid();
errors = user.errorsOnBase();
// errors -&gt; [{property: &quot;&quot;, message: &quot;Account has been suspended&quot;, name: &quot;&quot;}]

// 2. Filter base errors by a specific error name
user.addErrorToBase(message=&quot;Account has been suspended&quot;, name=&quot;suspended&quot;);
user.addErrorToBase(message=&quot;Please accept the terms&quot;, name=&quot;terms&quot;);
suspendedErrors = user.errorsOnBase(name=&quot;suspended&quot;);
// suspendedErrors -&gt; [{property: &quot;&quot;, message: &quot;Account has been suspended&quot;, name: &quot;suspended&quot;}]

// 3. Check for base errors and display them
errors = user.errorsOnBase();
if (arrayLen(errors)) {
    for (e in errors) {
        writeOutput(e.message);
    }
}
</code></pre>
