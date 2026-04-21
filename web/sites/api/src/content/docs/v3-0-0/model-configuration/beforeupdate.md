---
title: beforeUpdate()
description: "Registers method(s) that should be called before an existing object is updated. This is useful for enforcing rules, transforming values, or checking conditions"
sidebar:
  label: beforeUpdate()
  order: 0
---

## Signature

`beforeUpdate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before an existing object is updated. This is useful for enforcing rules, transforming values, or checking conditions specifically for update operations (unlike beforeSave(), which applies to both create and update).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>1. Basic usage: register a method before update
function config() {
    beforeUpdate("fixObj");
}

function fixObj() {
    // Example: trim whitespace before updating
    this.lastName = trim(this.lastName);
}

2. Update an \"last modified\" timestamp
function config() {
    beforeUpdate("updateTimestamp");
}

function updateTimestamp() {
    this.updatedAt = now();
}

3. Prevent updating sensitive fields
function config() {
    beforeUpdate("restrictEmailChange");
}

function restrictEmailChange() {
    if (this.hasChanged("email")) {
        throw(type="ValidationException", message="Email address cannot be changed.");
    }
}

4. Audit updates with logging
function config() {
    beforeUpdate("logChanges");
}

function logChanges() {
    var changes = this.allChanges();
    writeLog(text="User ##this.id## updated with changes: #serializeJSON(changes)#", file="audit");
}</code></pre>
