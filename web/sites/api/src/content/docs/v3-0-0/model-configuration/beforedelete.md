---
title: beforeDelete()
description: "Registers method(s) that should be called before an object is deleted. This allows you to perform cleanup, enforce constraints, or prevent deletion if certain c"
sidebar:
  label: beforeDelete()
  order: 0
---

## Signature

`beforeDelete()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before an object is deleted. This allows you to perform cleanup, enforce constraints, or prevent deletion if certain conditions are not met.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>1. Basic usage: run a method before deleting
function config() {
    beforeDelete("fixObj");
}

function fixObj() {
    // Example: log deletions
    writeLog("Deleting record with ID #this.id#");
}

2. Prevent deletion if conditions fail
function config() {
    beforeDelete("checkIfAdmin");
}

function checkIfAdmin() {
    if (!session.isAdmin) {
        throw(type="SecurityException", message="Only admins can delete records.");
    }
}

3. Cascade cleanup before deletion
function config() {
    beforeDelete("cleanupAssociations");
}

function cleanupAssociations() {
    // Delete related comments before removing a post
    model("comment").deleteAll(where="postId = #this.id#");
}</code></pre>
