---
title: post()
description: "Create a route that matches a URL requiring an HTTP <code>POST</code> method. We recommend using this matcher to expose actions that create database records."
sidebar:
  label: post()
  order: 0
---

## Signature

`post()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Create a route that matches a URL requiring an HTTP <code>POST</code> method. We recommend using this matcher to expose actions that create database records.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | — | Camel-case name of route to reference when build links and form actions (e.g., `blogPosts`). |
| `pattern` | `string` | no | — | Overrides the URL pattern that will match the route. The default value is a dasherized version of `name` (e.g., a `name` of `blogPosts` generates a pattern of `blog-posts`). |
| `to` | `string` | no | — | Set `controller##action` combination to map the route to. You may use either this argument or a combination of `controller` and `action`. |
| `controller` | `string` | no | — | Map the route to a given controller. This must be passed along with the `action` argument. |
| `action` | `string` | no | — | Map the route to a given action within the `controller`. This must be passed along with the `controller` argument. |
| `package` | `string` | no | — | Indicates a subfolder that the controller will be referenced from (but not added to the URL pattern). For example, if you set this to `admin`, the controller will be located at `admin/YourController.cfc`, but the URL path will not contain `admin/`. |
| `on` | `string` | no | — | If this route is within a nested resource, you can set this argument to `member` or `collection`. A `member` route contains a reference to the resource's `key`, while a `collection` route does not. |

</div>

## Examples

<pre>&lt;cfscript&gt;

mapper()
    // Route name:  widgets
    // Example URL: /sites/918/widgets
    // Controller:  Widgets
    // Action:      create
    .post(name=&quot;widgets&quot;, pattern=&quot;sites/[siteKey]/widgets&quot;, to=&quot;widgets##create&quot;)

    // Route name:  wadgets
    // Example URL: /wadgets
    // Controller:  Wadgets
    // Action:      create
    .post(name=&quot;wadgets&quot;, controller=&quot;wadgets&quot;, action=&quot;create&quot;)

    // Route name:  authenticate
    // Example URL: /oauth/token.json
    // Controller:  Tokens
    // Action:      create
    .post(name=&quot;authenticate&quot;, pattern=&quot;oauth/token.json&quot;, to=&quot;tokens##create&quot;)

    // Route name:  usersPreferences
    // Example URL: /preferences
    // Controller:  users.Preferences
    // Action:      create
    .post(name=&quot;preferences&quot;, to=&quot;preferences##create&quot;, package=&quot;users&quot;)

    // Route name:  extranetOrders
    // Example URL: /buy-now/orders
    // Controller:  extranet.Orders
    // Action:      create
    .post(
        name=&quot;orders&quot;,
        pattern=&quot;buy-now/orders&quot;,
        to=&quot;orders##create&quot;,
        package=&quot;extranet&quot;
    )

    // Example scoping within a nested resource
    .resources(name=&quot;customers&quot;, nested=true)
        // Route name:  leadsCustomers
        // Example URL: /customers/leads
        // Controller:  Leads
        // Action:      create
        .post(name=&quot;leads&quot;, to=&quot;leads##create&quot;, on=&quot;collection&quot;)

        // Route name:  cancelCustomer
        // Example URL: /customers/3209/cancel
        // Controller:  Cancellations
        // Action:      create
        .post(name=&quot;cancel&quot;, to=&quot;cancellations##create&quot;, on=&quot;member&quot;)
    .end()
.end();

&lt;/cfscript&gt;</pre>
