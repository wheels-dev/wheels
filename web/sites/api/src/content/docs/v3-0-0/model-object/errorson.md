---
title: errorsOn()
description: "errorsOn() returns an array of all errors associated with a specific property of a model object. You can also filter by a specific error name if needed. This is"
sidebar:
  label: errorsOn()
  order: 0
---

## Signature

`errorsOn()` — returns `array`

**Available in:** `model`
**Category:** Error Functions

## Description

errorsOn() returns an array of all errors associated with a specific property of a model object. You can also filter by a specific error name if needed. This is useful when you need programmatic access to errors rather than just displaying them in the view.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Specify the property name to return errors for here. |
| `name` | `string` | no | — | If you want to return only errors on the property set with a specific error name you can specify it here. |

</div>

## Examples

<pre><code class='javascript'>Example 1 — Basic usage
&lt;cfscript&gt;
user = model(&quot;user&quot;).findByKey(12);

errors = user.errorsOn(&quot;emailAddress&quot;);

writeDump(errors);
&lt;/cfscript&gt;

Returns an array of error objects associated with the emailAddress property.

Each element typically contains the error message and metadata like name or type.

Example 2 — Filter by error name
&lt;cfscript&gt;
errors = user.errorsOn(&quot;emailAddress&quot;, &quot;uniqueEmail&quot;);

writeDump(errors);
&lt;/cfscript&gt;

Returns only errors for emailAddress that have the error name uniqueEmail.

Example 3 — Checking if a property has any errors
&lt;cfscript&gt;
if (arrayLen(user.errorsOn(&quot;password&quot;)) &gt; 0) {
 writeOutput(&quot;Password has errors!&quot;);
}
&lt;/cfscript&gt;

This is helpful when you need conditional logic based on whether a field has errors.

Example 4 — Iterating over errors
&lt;cfscript&gt;
errors = user.errorsOn(&quot;username&quot;);

for (var e in errors) {
 writeOutput(&quot;Error: &quot; & e.message & &quot;&lt;br&gt;&quot;);
}
&lt;/cfscript&gt;

Loops through all errors on a property and outputs the messages individually.
</code></pre>
