---
title: beforeValidation()
description: "Registers method(s) that should be called before an object is validated. This hook is helpful when you want to adjust, normalize, or clean up data before valida"
sidebar:
  label: beforeValidation()
  order: 0
---

## Signature

`beforeValidation()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before an object is validated. This hook is helpful when you want to adjust, normalize, or clean up data before validation rules run. It ensures the object is in the correct state so that validations pass or fail as expected.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre><code class='javascript'>1. Basic usage: register a method before validation
function config() {
    beforeValidation("fixObj");
}

function fixObj() {
    // Example: normalize names before validation
    this.firstName = trim(this.firstName);
    this.lastName = trim(this.lastName);
}

2. Ensure default values before validation
function config() {
    beforeValidation("setDefaults");
}

function setDefaults() {
    if (!len(this.status)) {
        this.status = "pending";
    }
}

3. Convert input formats before validating
function config() {
    beforeValidation("normalizePhone");
}

function normalizePhone() {
    // Remove spaces/dashes so the validation regex can run correctly
    this.phoneNumber = rereplace(this.phoneNumber, "[^0-9]", "", "all");
}

4. Multi-method callback
function config() {
    beforeValidation("sanitizeEmail, normalizeUsername");
}

function sanitizeEmail() {
    this.email = lcase(trim(this.email));
}

function normalizeUsername() {
    this.username = rereplace(this.username, "[^a-zA-Z0-9]", "", "all");
}</code></pre>
