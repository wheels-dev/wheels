---
title: afterValidation()
description: "Registers one or more callback methods that should be executed after an object has been validated. This hook is useful for running extra logic that depends on v"
sidebar:
  label: afterValidation()
  order: 0
---

## Signature

`afterValidation()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers one or more callback methods that should be executed after an object has been validated. This hook is useful for running extra logic that depends on validation results, such as adjusting error messages, performing side validations, or preparing data before saving.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>1. Add a custom validation error
afterValidation("checkRestrictedEmails");

function checkRestrictedEmails() {
    if (listFindNoCase("test@example.com,admin@example.com", this.email)) {
        this.addError("email", "That email address is not allowed.");
    }
}

2. Normalize data after validation
afterValidation("normalizePhone");

function normalizePhone() {
    if (len(this.phone)) {
        this.phone = rereplace(this.phone, "[^0-9]", "", "all");
    }
}

3. Multiple callbacks
afterValidation("checkRestrictedEmails,normalizePhone");

4. Example in User.cfc
component extends="Model" {
    function config() {
        validatesPresenceOf("email");
        afterValidation("checkRestrictedEmails,normalizePhone");
    }

    function checkRestrictedEmails() {
        if (listFindNoCase("banned@example.com", this.email)) {
            this.addError("email", "This email address is not permitted.");
        }
    }

    function normalizePhone() {
        this.phone = rereplace(this.phone, "[^0-9]", "", "all");
    }
}</code></pre>
