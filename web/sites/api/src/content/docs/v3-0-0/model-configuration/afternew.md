---
title: afterNew()
description: "Registers one or more callback methods that should be executed after a new object has been initialized, typically via the new() method. This hook is useful for"
sidebar:
  label: afterNew()
  order: 0
---

## Signature

`afterNew()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers one or more callback methods that should be executed after a new object has been initialized, typically via the new() method. This hook is useful for setting default values, preparing derived attributes, or running logic every time you create a fresh model instance (before saving it to the database).



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre><code class='javascript'>1. Set default values for new records
afterNew("setDefaults");

function setDefaults() {
    this.isActive = true;
    this.role = "member";
}

Whenever a new object is initialized, default values are assigned.

2. Generate a temporary property
afterNew("assignTempId");

function assignTempId() {
    this.tempId = createUUID();
}

Each new object will have a unique tempId until it’s saved.

3. Multiple callbacks
afterNew("setDefaults,assignTempId");

Runs both methods sequentially for every new object.

4. Example in User.cfc
component extends="Model" {
    function config() {
        afterNew("setDefaults,prepareDisplayName");
    }

    function setDefaults() {
        this.isActive = true;
    }

    function prepareDisplayName() {
        this.displayName = this.firstName & " " & this.lastName;
    }
}</code></pre>
