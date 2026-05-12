---
title: errorsOnBase()
description: "errorsOnBase() returns an array of all errors associated with the object as a whole, not tied to any specific property. This is useful for general errors such a"
sidebar:
  label: errorsOnBase()
  order: 0
---

## Signature

`errorsOnBase()` — returns `array`

**Available in:** `model`
**Category:** Error Functions

## Description

errorsOnBase() returns an array of all errors associated with the object as a whole, not tied to any specific property. This is useful for general errors such as system-level validations, cross-field validations, or custom errors added at the object level.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | — | Specify an error name here to only return errors for that error name. |

</div>

## Examples

<pre><code class='javascript'>Example 1 — Get all base errors
&lt;cfscript&gt;
user = model(&quot;user&quot;).findByKey(12);

errors = user.errorsOnBase();

writeDump(errors);
&lt;/cfscript&gt;

Returns all general errors on the user object.

Each element typically contains message, name, and type information.

Example 2 — Filter by error name
&lt;cfscript&gt;
errors = user.errorsOnBase(&quot;accountLocked&quot;);

writeDump(errors);
&lt;/cfscript&gt;

Returns only base errors that have the error name accountLocked.

Example 3 — Conditional logic with base errors
&lt;cfscript&gt;
if (arrayLen(user.errorsOnBase()) &gt; 0) {
 writeOutput(&quot;There are general errors on this user account.&quot;);
}
&lt;/cfscript&gt;

This can be used to block actions or display notices when object-level errors exist.

Example 4 — Iterating over base errors
&lt;cfscript&gt;
for (var e in user.errorsOnBase()) {
 writeOutput(&quot;General error: &quot; & e.message & &quot;&lt;br&gt;&quot;);
}
&lt;/cfscript&gt;

Loops through each object-level error and outputs its message.
</code></pre>
