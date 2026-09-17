---
title: callbackInfo()
description: "Returns a struct containing all callback definitions for this model, keyed by callback type"
sidebar:
  label: callbackInfo()
  order: 0
---

## Signature

`callbackInfo()` — returns `struct`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a struct containing all callback definitions for this model, keyed by callback type
(e.g., <code>beforeSave</code>, <code>afterCreate</code>). Each callback type contains an array of callback method names.




## Examples

<pre><code class='javascript'>// 1. Inspect all registered callbacks for a model
info = model(&quot;Order&quot;).callbackInfo();
// info is a struct keyed by callback type, each containing an array of method names:
// {
//   beforeSave:               [&quot;stampUpdatedAt&quot;],
//   afterCreate:              [&quot;sendConfirmationEmail&quot;],
//   afterSave:                [&quot;clearCacheEntries&quot;],
//   beforeValidation:         [],
//   beforeValidationOnCreate: [],
//   afterValidation:          [],
//   afterFind:                [],
//   ...
// }

// 2. Check whether a specific callback type has any registered methods
info = model(&quot;User&quot;).callbackInfo();
if (arrayLen(info.beforeDelete)) {
    writeOutput(&quot;User model has beforeDelete callbacks.&quot;);
}

// 3. Loop over all callback types and their methods for debugging
info = model(&quot;Post&quot;).callbackInfo();
for (callbackType in info) {
    for (methodName in info[callbackType]) {
        writeOutput(callbackType &amp; &quot;: &quot; &amp; methodName);
    }
}
</code></pre>
