---
title: afterFind()
description: "Registers one or more callback methods that should be executed after an existing object has been initialized, typically via finder methods such as findByKey, fi"
sidebar:
  label: afterFind()
  order: 0
---

## Signature

`afterFind()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers one or more callback methods that should be executed after an existing object has been initialized, typically via finder methods such as findByKey, findOne, findAll, or other query-based lookups. This hook is useful for adjusting, enriching, or transforming model objects immediately after they are loaded from the database.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>1. Add a timestamp when data was fetched
component extends="Model" {
    function config() {
        afterFind("setTime");
    }

    function setTime() {
        arguments.fetchedAt = now();
        return arguments;
    }
}

When you call:

user = model("User").findByKey(1);
writeOutput(user.fetchedAt); // Shows the time record was retrieved

2. Format or normalize data
afterFind("normalizeEmail");

function normalizeEmail() {
    this.email = lcase(this.email);
}

Ensures all email addresses are lowercased when loaded.

3. Load related info automatically
afterFind("attachProfile");

function attachProfile() {
    this.profile = model("Profile").findOne(where="userId = #this.id#");
}

Now every User object automatically has its related profile loaded.

4. Multiple callbacks
afterFind("setTime,normalizeEmail,attachProfile");

All three methods will run in order after the object is retrieved.</code></pre>
