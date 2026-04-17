---
title: beforeCreate()
description: "Registers method(s) that should be called before a new object is created. This allows you to modify or validate data, set defaults, or perform logic right befor"
sidebar:
  label: beforeCreate()
  order: 0
---

## Signature

`beforeCreate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before a new object is created. This allows you to modify or validate data, set defaults, or perform logic right before the object is persisted in the database for the first time.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre><code class='javascript'>1. Run a method before saving a new object
function config() {
    beforeCreate("fixObj");
}

function fixObj() {
    // Ensure a default role is assigned
    if (!structKeyExists(this, "roleId")) {
        this.roleId = 2; // Assign "user" role
    }
}

2. Generate a unique slug before creation
function config() {
    beforeCreate("generateSlug");
}

function generateSlug() {
    this.slug = lcase(replace(this.title, " ", "-", "all"));
}

3. Hash a password before inserting a new user
function config() {
    beforeCreate("hashPassword");
}

function hashPassword() {
    this.password = hash(this.password, "SHA-256");
}</code></pre>
