---
title: afterValidationOnCreate()
description: "Registers one or more callback methods that should be executed after a new object has been validated (i.e., when running validations during a create() or save()"
sidebar:
  label: afterValidationOnCreate()
  order: 0
---

## Signature

`afterValidationOnCreate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers one or more callback methods that should be executed after a new object has been validated (i.e., when running validations during a create() or save() on a new record). This hook is useful when you want to apply custom logic only during new record creation, not during updates.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>1. Add a creation-only error
afterValidationOnCreate("checkSignupEmail");

function checkSignupEmail() {
    if (listFindNoCase("banned@example.com,blocked@example.com", this.email)) {
        this.addError("email", "This email address cannot be used for registration.");
    }
}

2. Generate a default username if missing
afterValidationOnCreate("generateUsername");

function generateUsername() {
    if (!len(this.username)) {
        this.username = listFirst(this.email, "@");
    }
}

3. Multiple callbacks
afterValidationOnCreate("checkSignupEmail,generateUsername");

4. Example in User.cfc
component extends="Model" {
    function config() {
        validatesPresenceOf("email");
        validatesFormatOf(property="email", regex="^[\w\.-]+@[\w\.-]+\.\w+$");

        afterValidationOnCreate("checkSignupEmail,generateUsername");
    }

    function checkSignupEmail() {
        if (listFindNoCase("banned@example.com", this.email)) {
            this.addError("email", "This email address is restricted.");
        }
    }

    function generateUsername() {
        if (!len(this.username)) {
            this.username = listFirst(this.email, "@");
        }
    }
}</code></pre>
