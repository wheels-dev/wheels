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

<pre><code class='javascript'>1. Get all validation errors
user = model("user").new(
    username = "",
    password = ""
);

// Validate the object
user.valid();

// Fetch errors
errorInfo = user.allErrors();

writeDump(var=errorInfo, label="User Errors");

Sample output:

[
  {
    "message": "Username must not be blank.",
    "name": "PresenceOf",
    "property": "username"
  },
  {
    "message": "Password must not be blank.",
    "name": "PresenceOf",
    "property": "password"
  }
]

2. Including associated model errors
order = model("order").new(
    customer = model("customer").new(name="")
);

// Validate both order and associated customer
order.valid();

// Get errors from both order and customer
errors = order.allErrors(includeAssociations=true);

3. Checking for errors before saving
user = model("user").new(email="not-an-email");

if (!user.valid()) {
    errors = user.allErrors();
    for (err in errors) {
        writeOutput("Error on #err.property#: #err.message#");
    }
}</code></pre>
