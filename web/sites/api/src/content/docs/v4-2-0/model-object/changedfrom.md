---
title: changedFrom()
description: "Returns the previous value of a property that has changed."
sidebar:
  label: changedFrom()
  order: 0
---

## Signature

`changedFrom()` — returns `string`

**Available in:** `model`
**Category:** Change Functions

## Description

Returns the previous value of a property that has changed.
Returns an empty string if no previous value exists.
Wheels will keep a note of the previous property value until the object is saved to the database.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to get the previous value for. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get the previous value of a changed property
user = model(&quot;User&quot;).findByKey(params.userId);
user.email = params.newEmail;

// Returns the original email address before it was changed
oldEmail = user.changedFrom(&quot;email&quot;);
// oldEmail -&gt; &quot;original@example.com&quot;

// 2. Use the dynamic shorthand method (equivalent to the above)
oldEmail = user.emailChangedFrom();

// 3. Check if a property changed before accessing the previous value
user = model(&quot;User&quot;).findByKey(params.userId);
user.firstName = params.firstName;

if (user.hasChanged(&quot;firstName&quot;)) {
	oldName = user.changedFrom(&quot;firstName&quot;);
	// oldName -&gt; &quot;Jane&quot;
}
// Returns empty string if property has not changed or no previous value exists
</code></pre>
