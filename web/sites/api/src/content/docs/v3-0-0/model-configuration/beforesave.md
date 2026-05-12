---
title: beforeSave()
description: "Registers method(s) that should be called before an object is saved. This is useful for performing transformations, validations, or logging before data is persi"
sidebar:
  label: beforeSave()
  order: 0
---

## Signature

`beforeSave()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before an object is saved. This is useful for performing transformations, validations, or logging before data is persisted.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>1. Basic usage: run a method before save
function config() {
    beforeSave("fixObj");
}

function fixObj() {
    // Example: Trim whitespace before saving
    this.username = trim(this.username);
}

2. Automatically update a timestamp
function config() {
    beforeSave("updateTimestamp");
}

function updateTimestamp() {
    this.lastModifiedAt = now();
}

3. Normalize data before saving
function config() {
    beforeSave("normalizeData");
}

function normalizeData() {
    // Example: ensure email is lowercase
    this.email = lcase(this.email);

    // Example: capitalize first name
    this.firstName = ucase(left(this.firstName, 1)) & mid(this.firstName, 2);
}

4. Prevent save if conditions fail
function config() {
    beforeSave("blockInactiveUsers");
}

function blockInactiveUsers() {
    if (!this.isActive) {
        throw(type="ValidationException", message="Inactive users cannot be saved.");
    }
}</code></pre>
