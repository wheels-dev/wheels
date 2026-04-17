---
title: afterSave()
description: "Registers one or more callback methods that should be executed after an object is saved to the database. This hook runs whether the save was the result of creat"
sidebar:
  label: afterSave()
  order: 0
---

## Signature

`afterSave()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers one or more callback methods that should be executed after an object is saved to the database. This hook runs whether the save was the result of creating a new record or updating an existing one. It’s ideal for tasks that must happen after persistence, such as logging, syncing data, or triggering external processes.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre><code class='javascript'>1. Log every save
afterSave("logSave");

function logSave() {
    writeLog("User ##this.id## saved at #now()#");
}

2. Trigger notifications
afterSave("notifyAdmin");

function notifyAdmin() {
    if (this.role == "admin") {
        sendEmail(to="superadmin@example.com", subject="Admin Updated", body="Admin user #this.id# has been updated.");
    }
}

3. Multiple callbacks
afterSave("logSave,notifyAdmin");

4. Example in Order.cfc
component extends="Model" {
    function config() {
        afterSave("recalculateInventory,sendConfirmation");
    }

    function recalculateInventory() {
        Inventory.updateStock(this.productId, -this.quantity);
    }

    function sendConfirmation() {
        EmailService.sendOrderConfirmation(this.id);
    }
}</code></pre>
