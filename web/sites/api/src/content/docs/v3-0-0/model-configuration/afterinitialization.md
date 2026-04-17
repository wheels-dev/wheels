---
title: afterInitialization()
description: "Registers one or more callback methods that should be executed after an object has been initialized. Initialization happens in two cases, When a new object is c"
sidebar:
  label: afterInitialization()
  order: 0
---

## Signature

`afterInitialization()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers one or more callback methods that should be executed after an object has been initialized. Initialization happens in two cases, When a new object is created (via new() or similar) or when an existing object is fetched from the database (via findByKey, findOne, etc.). This makes afterInitialization() more general than afterCreate() or afterFind(), since it runs in both scenarios.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre><code class='javascript'>1. Normalize data after every initialization
afterInitialization("normalizeName");

function normalizeName() {
    this.firstName = trim(this.firstName);
    this.lastName = trim(this.lastName);
}

Ensures whitespace is stripped whether the object is new or fetched.

2. Add a helper attribute for all instances
afterInitialization("addFullName");

function addFullName() {
    this.fullName = this.firstName & " " & this.lastName;
}

Now every object has a fullName property set right after creation or retrieval.

3. Multiple callbacks
afterInitialization("normalizeName,addFullName");

Runs both methods sequentially.

4. Practical example in User.cfc
component extends="Model" {
    function config() {
        afterInitialization("normalizeName,addFullName,setFetchedAt");
    }

    function normalizeName() {
        this.firstName = trim(this.firstName);
        this.lastName = trim(this.lastName);
    }

    function addFullName() {
        this.fullName = this.firstName & " " & this.lastName;
    }

    function setFetchedAt() {
        arguments.fetchedAt = now();
        return arguments;
    }
}</code></pre>
