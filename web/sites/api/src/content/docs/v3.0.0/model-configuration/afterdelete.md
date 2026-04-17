---
title: afterDelete()
description: "Registers one or more callback methods that should be executed after an object is deleted from the database. This hook allows you to perform cleanup, logging, o"
sidebar:
  label: afterDelete()
  order: 0
---

## Signature

`afterDelete()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers one or more callback methods that should be executed after an object is deleted from the database. This hook allows you to perform cleanup, logging, or side effects when a record has been removed.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre><code class='javascript'>1. Single callback method
// Call `logDeletion` after an object is deleted
afterDelete("logDeletion");

function logDeletion() {
    writeLog("Record deleted at #now()#");
}

2. Multiple callbacks
afterDelete("archiveData,notifyAdmin");

function archiveData() {
    // move deleted data to an archive table
}

function notifyAdmin() {
    // send a notification email
}

3. With related cleanup
afterDelete("removeAssociatedRecords");

function removeAssociatedRecords() {
    // remove orphaned child records manually
    Order.deleteAll(where="userId = #this.id#");
}

4. Practical usage in User.cfc
component extends="Model" {
    function config() {
        afterDelete("cleanupSessions,sendGoodbyeEmail");
    }

    function cleanupSessions() {
        Session.deleteAll(where="userId = #id#");
    }

    function sendGoodbyeEmail() {
        // code to send a farewell email
    }
}</code></pre>
