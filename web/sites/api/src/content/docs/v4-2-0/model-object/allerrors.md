---
title: allErrors()
description: "Returns an array of all the errors on the object."
sidebar:
  label: allErrors()
  order: 0
---

## Signature

`allErrors()` — returns `array`

**Available in:** `model`
**Category:** Error Functions

## Description

Returns an array of all the errors on the object.


It does this by storing instances of models that are associations, and not checking associations of those instances because they have already been checked.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `includeAssociations` | `boolean` | no | `false` |  |
| `seenErrors` | `array` | no | `[runtime expression]` | is a private argument not meant to be used by the user, the function uses this to ensure circular dependency avoidance. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get all errors on a model object after a failed validation
user = model(&quot;User&quot;).new(username=&quot;&quot;, password=&quot;&quot;);
user.valid();
errors = user.allErrors();
// errors -&gt;
// [
//   { message: &quot;Username must not be blank.&quot;, name: &quot;&quot;, property: &quot;username&quot; },
//   { message: &quot;Password must not be blank.&quot;, name: &quot;&quot;, property: &quot;password&quot; }
// ]

// 2. Check for errors and iterate over them
if (user.hasErrors()) {
	for (error in user.allErrors()) {
		writeOutput(error.property &amp; &quot;: &quot; &amp; error.message);
	}
}

// 3. Include errors from associated models (e.g. a user with associated profile)
user = model(&quot;User&quot;).findOne(where=&quot;id=1&quot;, include=&quot;profile&quot;);
user.valid();
allErrors = user.allErrors(includeAssociations=true);
// allErrors contains errors from both user and its associated profile model
</code></pre>
