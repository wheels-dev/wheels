---
title: afterCreate()
description: "Registers one or more callback methods that are automatically executed after a new object is created (i.e., after calling create() on a model). This is part of"
sidebar:
  label: afterCreate()
  order: 0
---

## Signature

`afterCreate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers one or more callback methods that are automatically executed after a new object is created (i.e., after calling create() on a model). This is part of the model lifecycle callbacks in Wheels.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>1. Single callback method
// Instruct Wheels to call the `fixObj` method after an object is created
afterCreate("fixObj");

function fixObj() {
    variables.fixed = true;
}

2. Multiple callbacks
afterCreate("logCreation,notifyAdmin");

function logCreation() {
    writeLog("New record created at #now()#");
}

function notifyAdmin() {
    // send an email notification
}

3. With object attributes
afterCreate("setDefaults");

function setDefaults() {
    if (!len(variables.status)) {
        variables.status = "pending";
    }
}

4. Practical usage in User.cfc
component extends="Model" {
    function config() {
        afterCreate("assignRole,sendWelcomeEmail");
    }

    function assignRole() {
        if (isNull(roleId)) {
            roleId = Role.findOneByName("User").id;
        }
    }

    function sendWelcomeEmail() {
        // code to send welcome email
    }
}</code></pre>
