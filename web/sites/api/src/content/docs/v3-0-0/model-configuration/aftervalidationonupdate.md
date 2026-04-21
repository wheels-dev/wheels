---
title: afterValidationOnUpdate()
description: "Registers one or more callback methods that should be executed after an existing object has been validated (i.e., when running validations during an update() or"
sidebar:
  label: afterValidationOnUpdate()
  order: 0
---

## Signature

`afterValidationOnUpdate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers one or more callback methods that should be executed after an existing object has been validated (i.e., when running validations during an update() or save() on an already-persisted record). This hook is useful when you want logic to run only on updates, not on initial creation.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>1. Prevent updating restricted emails
afterValidationOnUpdate("checkRestrictedEmail");

function checkRestrictedEmail() {
    if (this.email eq "admin@example.com") {
        this.addError("email", "You cannot change this email address.");
    }
}

2. Automatically update a lastModifiedBy field
afterValidationOnUpdate("setLastModifiedBy");

function setLastModifiedBy() {
    this.lastModifiedBy = session.userId;
}

3. Multiple callbacks
afterValidationOnUpdate("checkRestrictedEmail,setLastModifiedBy");

4. Example in User.cfc
component extends="Model" {
    function config() {
        validatesPresenceOf("email");
        validatesFormatOf(property="email", regex="^[\w\.-]+@[\w\.-]+\.\w+$");

        afterValidationOnUpdate("checkRestrictedEmail,setLastModifiedBy");
    }

    function checkRestrictedEmail() {
        if (this.email eq "admin@example.com") {
            this.addError("email", "This email cannot be changed.");
        }
    }

    function setLastModifiedBy() {
        this.lastModifiedBy = session.userId;
    }
}</code></pre>
