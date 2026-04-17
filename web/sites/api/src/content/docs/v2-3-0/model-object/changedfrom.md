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
CFWheels will keep a note of the previous property value until the object is saved to the database.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to get the previous value for. |

## Examples

<pre><code class='javascript'>// Get a member object and change the `email` property on it
member = model(&quot;member&quot;).findByKey(params.memberId);
member.email = params.newEmail;

// Get the previous value (what the `email` property was before it was changed)
oldValue = member.changedFrom(&quot;email&quot;);

// The above can also be done using a dynamic function like this
oldValue = member.emailChangedFrom();</code></pre>
