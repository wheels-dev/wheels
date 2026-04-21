---
title: dropView()
description: "dropView() is used to remove a database view entirely. A view is a saved query that acts like a virtual table, so this operation deletes that virtual table defi"
sidebar:
  label: dropView()
  order: 0
---

## Signature

`dropView()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

dropView() is used to remove a database view entirely. A view is a saved query that acts like a virtual table, so this operation deletes that virtual table definition. Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the view to drop |

</div>

## Examples

<pre><code class='javascript'>function down() {
    // Drop the 'active_users' view
    dropView(name="active_users");
}

name = "active_users" -> the view that you want to remove from the database.

Notes

Typically used in the down() method of a migration when rolling back a previous createView().

Can be wrapped in a transaction for safety:

function down() {
    transaction {
        try {
            dropView("recent_orders");
        } catch (any e) {
            transaction action="rollback";
            throw(errorCode="1", detail=e.detail, message=e.message, type="any");
        }
        transaction action="commit";
    }
}

Caution: This permanently deletes the view definition. Any queries depending on the view will fail after this operation.</code></pre>
