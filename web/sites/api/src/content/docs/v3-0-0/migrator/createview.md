---
title: createView()
description: "The createView() function is used in migration CFCs to define a new database view. It returns a ViewDefinition object, on which you can specify the view’s SQL q"
sidebar:
  label: createView()
  order: 0
---

## Signature

`createView()` — returns `ViewDefinition`

**Available in:** `migration`
**Category:** Migration Functions

## Description

The createView() function is used in migration CFCs to define a new database view. It returns a ViewDefinition object, on which you can specify the view’s SQL query and properties. Once the view is fully defined, you call create() to actually create it in the database.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the view to change properties on |

</div>

## Examples

<pre><code class='javascript'>1. Simple View Creation

v = createView(name='active_users');
v.selectStatement(sql = "SELECT * FROM c_o_r_e_users")
v.create();

// Creates a view active_users that selects only active users from the users table.

2. View with Join

v = createView(name='user_orders');
v.selectStatement(sql = "SELECT u.id, u.firstname, u.lastname, o.id AS orderId, o.total FROM users u JOIN orders o ON u.id = o.userId WHERE o.status = "completed";")
v.create();

// Creates a user_orders view joining users and orders tables, filtering only completed orders.</code></pre>
