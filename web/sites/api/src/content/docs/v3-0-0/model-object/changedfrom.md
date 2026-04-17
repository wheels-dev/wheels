---
title: changedFrom()
description: "Returns the previous value of a property that has been modified on a model object. Wheels tracks changes to object properties until the object is saved to the d"
sidebar:
  label: changedFrom()
  order: 0
---

## Signature

`changedFrom()` — returns `string`

**Available in:** `model`
**Category:** Change Functions

## Description

Returns the previous value of a property that has been modified on a model object. Wheels tracks changes to object properties until the object is saved to the database. If no previous value exists (the property was never modified), it returns an empty string. This is useful for auditing, logging, or conditional logic based on changes to object properties.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to get the previous value for. |

## Examples

<pre><code class='javascript'>1. Track changes on a single property
member = model("member").findByKey(params.memberId);
member.email = params.newEmail;

// Get the previous value of the email
oldValue = member.changedFrom("email");

2. Using dynamic property function
// Dynamic method naming also works
oldValue = member.emailChangedFrom();

3. Check before saving
member.firstName = "Bruce";

if (member.changedFrom("firstName") != "") {
    writeOutput("First name was changed from " & member.changedFrom("firstName"));
}

member.save();</code></pre>
