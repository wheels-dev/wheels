---
title: validationInfo()
description: "Returns a struct containing all validation rules for this model, keyed by trigger (<code>onSave</code>, <code>onCreate</code>, <code>onUpdate</code>)."
sidebar:
  label: validationInfo()
  order: 0
---

## Signature

`validationInfo()` — returns `struct`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a struct containing all validation rules for this model, keyed by trigger (<code>onSave</code>, <code>onCreate</code>, <code>onUpdate</code>).
Each trigger contains an array of validation rule structs with <code>method</code>, <code>properties</code>, <code>message</code>, and other parameters.




## Examples

<pre><code class='javascript'>// 1. Inspect all validation rules defined on the User model
info = model(&quot;User&quot;).validationInfo();
// info is keyed by trigger: onSave, onCreate, onUpdate
// Each key holds an array of rule structs, e.g.:
// info.onSave[1] -&gt; {method: &quot;validatesPresenceOf&quot;, properties: &quot;email&quot;, message: &quot;can't be blank&quot;, ...}
// info.onCreate -&gt; []
// info.onUpdate -&gt; []

// 2. Count how many rules fire on every save
info = model(&quot;User&quot;).validationInfo();
writeOutput(&quot;Rules on save: &quot; &amp; arrayLen(info.onSave));

// 3. List the validation methods used across all triggers
info = model(&quot;User&quot;).validationInfo();
for (trigger in info) {
    for (rule in info[trigger]) {
        writeOutput(trigger &amp; &quot;: &quot; &amp; rule.method &amp; &quot; on &quot; &amp; rule.properties);
    }
}
</code></pre>
