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
| `redirect` | `string` | no | — | Redirect via 302 to this URL when this route is matched. Has precedence over controller/action. Use either an absolute link like `/about/`, or a full canonical link. |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    // 1. Basic POST route using `to` shorthand (controller##action)
    // Route name:  widgets
    // Example URL: /sites/918/widgets
    // Controller:  Widgets
    // Action:      create
    .post(name=&quot;widgets&quot;, pattern=&quot;sites/[siteKey]/widgets&quot;, to=&quot;widgets##create&quot;)

    // 2. POST route using explicit `controller` and `action` arguments
    // Route name:  wadgets
    // Example URL: /wadgets
    // Controller:  Wadgets
    // Action:      create
    .post(name=&quot;wadgets&quot;, controller=&quot;wadgets&quot;, action=&quot;create&quot;)

    // 3. POST route with a custom URL pattern (e.g., format-bearing endpoint)
    // Route name:  authenticate
    // Example URL: /oauth/token.json
    // Controller:  Tokens
    // Action:      create
    .post(name=&quot;authenticate&quot;, pattern=&quot;oauth/token.json&quot;, to=&quot;tokens##create&quot;)

    // 4. POST route scoped to a package (subfolder) — package not in URL
    // Route name:  usersPreferences
    // Example URL: /preferences
    // Controller:  users.Preferences
    // Action:      create
    .post(name=&quot;preferences&quot;, to=&quot;preferences##create&quot;, package=&quot;users&quot;)

    // 5. POST route with both a custom pattern and a package
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

    // 6. POST route that issues a 302 redirect instead of dispatching to a controller
    // Route name:  legacySignup
    // Example URL: /signup  →  redirects to /register
    .post(name=&quot;legacySignup&quot;, pattern=&quot;signup&quot;, redirect=&quot;/register&quot;)

    // 7. POST routes nested inside a `resources` block using `on`
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

&lt;/cfscript&gt;
</code></pre>
