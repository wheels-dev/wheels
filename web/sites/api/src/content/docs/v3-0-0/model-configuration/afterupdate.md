---
title: afterUpdate()
description: "Registers one or more callback methods that should be executed after an existing object has been updated in the database. This hook is ideal for performing foll"
sidebar:
  label: afterUpdate()
  order: 0
---

## Signature

`afterUpdate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers one or more callback methods that should be executed after an existing object has been updated in the database. This hook is ideal for performing follow-up tasks whenever a record changes — such as logging, cache invalidation, or sending notifications about updates.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre><code class='javascript'>1. Simple logging
afterUpdate("logUpdate");

function logUpdate() {
    writeLog("Record ##this.id## was updated at #now()#");
}

2. Trigger an email when a specific field changes
afterUpdate("notifyEmailChange");

function notifyEmailChange() {
    if (this.hasChanged("email")) {
        sendEmail(
            to=this.email,
            subject="Your email was updated",
            body="Hi #this.firstName#, your email address has been changed."
        );
    }
}

3. Multiple callbacks
afterUpdate("logUpdate,notifyEmailChange");

4. Example in Order.cfc
component extends="Model" {
    function config() {
        afterUpdate("updateInventory,sendUpdateNotification");
    }

    function updateInventory() {
        Inventory.adjustStock(this.productId, -this.quantity);
    }

    function sendUpdateNotification() {
        EmailService.sendOrderUpdate(this.id);
    }
}</code></pre>
