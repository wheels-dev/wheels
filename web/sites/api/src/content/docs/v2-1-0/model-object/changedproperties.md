---
title: changedProperties()
description: "Returns a list of the object properties that have been changed but not yet saved to the database."
sidebar:
  label: changedProperties()
  order: 0
---

## Signature

`changedProperties()` — returns `string`

**Available in:** `model`
**Category:** Change Functions

## Description

Returns a list of the object properties that have been changed but not yet saved to the database.




## Examples

<pre><code class='javascript'>// Get an object, change it, and then ask for its changes (will return a list of the property names that have changed, not the values themselves)
member = model(&quot;member&quot;).findByKey(params.memberId);
member.firstName = params.newFirstName;
member.email = params.newEmail;
changedProperties = member.changedProperties();</code></pre>
