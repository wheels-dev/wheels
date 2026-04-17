---
title: beforeValidationOnCreate()
description: "Registers method(s) that should be called before a new object is validated. This hook is useful when you want to prepare or sanitize data specifically for new r"
sidebar:
  label: beforeValidationOnCreate()
  order: 0
---

## Signature

`beforeValidationOnCreate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before a new object is validated. This hook is useful when you want to prepare or sanitize data specifically for new records, ensuring that validations run on properly formatted data. It will not run on updates—only on create() or new() + save() operations.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre><code class='javascript'>1. Basic usage: register a method before validation on create
function config() {
    beforeValidationOnCreate("fixObj");
}

function fixObj() {
    this.firstName = trim(this.firstName);
}

2. Ensure default values only for new records
function config() {
    beforeValidationOnCreate("setDefaults");
}

function setDefaults() {
    if (!len(this.role)) {
        this.role = "member";
    }
}

3. Normalize data formats for new users
function config() {
    beforeValidationOnCreate("normalizeNewUserData");
}

function normalizeNewUserData() {
    // Make sure emails are stored lowercase for new accounts
    this.email = lcase(trim(this.email));
}

4. Run multiple setup methods before new record validation
function config() {
    beforeValidationOnCreate("assignUUID, sanitizeName");
}

function assignUUID() {
    if (!len(this.uuid)) {
        this.uuid = createUUID();
    }
}

function sanitizeName() {
    this.fullName = trim(this.fullName);
}</code></pre>
