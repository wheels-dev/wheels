---
title: beforeValidationOnUpdate()
description: "Registers method(s) that should be called before an existing object is validated. This hook is useful when you want to adjust, sanitize, or enforce rules specif"
sidebar:
  label: beforeValidationOnUpdate()
  order: 0
---

## Signature

`beforeValidationOnUpdate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before an existing object is validated. This hook is useful when you want to adjust, sanitize, or enforce rules specifically for updates (not for new records). It ensures the object is in the correct state before validation checks run.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>1. Basic usage: register a method before validation on update
function config() {
    beforeValidationOnUpdate("fixObj");
}

function fixObj() {
    this.lastName = trim(this.lastName);
}

2. Prevent changes to immutable fields
function config() {
    beforeValidationOnUpdate("restrictImmutableFields");
}

function restrictImmutableFields() {
    if (this.hasChanged("email")) {
        this.addError(property="email", message="Email cannot be changed once set.");
    }
}

3. Normalize input before update validations
function config() {
    beforeValidationOnUpdate("sanitizePhone");
}

function sanitizePhone() {
    this.phoneNumber = rereplace(this.phoneNumber, "[^0-9]", "", "all");
}

4. Run multiple pre-validation methods for updates
function config() {
    beforeValidationOnUpdate("updateTimestamp, sanitizeNotes");
}

function updateTimestamp() {
    this.lastModified = now();
}

function sanitizeNotes() {
    this.notes = trim(this.notes);
}</code></pre>
