---
title: changedProperties()
description: "Returns a list of property names that have been modified on a model object but not yet saved to the database. This is useful for tracking which fields were upda"
sidebar:
  label: changedProperties()
  order: 0
---

## Signature

`changedProperties()` — returns `string`

**Available in:** `model`
**Category:** Change Functions

## Description

Returns a list of property names that have been modified on a model object but not yet saved to the database. This is useful for tracking which fields were updated, triggering specific actions based on changes, or performing conditional validation.




## Examples

<pre><code class='javascript'>1. Track changed properties
member = model("member").findByKey(params.memberId);
member.firstName = params.newFirstName;
member.email = params.newEmail;

// Get a list of properties that have changed
changedProperties = member.changedProperties();

2. Conditional logic based on changes
if (arrayLen(member.changedProperties()) > 0) {
    writeOutput("The following fields were changed: " & arrayToList(member.changedProperties()));
}</code></pre>
