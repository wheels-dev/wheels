---
title: allChanges()
description: "Returns a struct detailing all changes that have been made on the object but not yet saved to the database."
sidebar:
  label: allChanges()
  order: 0
---

## Signature

`allChanges()` — returns `struct`

**Available in:** `model`
**Category:** Change Functions

## Description

Returns a struct detailing all changes that have been made on the object but not yet saved to the database.




## Examples

<pre><code class='javascript'>// Get an object, change it, and then ask for its changes (will return a struct containing the changes, both property names and their values).
member = model(&quot;member&quot;).findByKey(params.memberId);
member.firstName = params.newFirstName;
member.email = params.newEmail;
allChanges = member.allChanges();
</code></pre>
