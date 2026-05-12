---
title: put()
description: "Create a route that matches a URL requiring an HTTP <code>PUT</code> method. We recommend using this matcher to expose actions that update database records. Thi"
sidebar:
  label: put()
  order: 0
---

## Signature

`put()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Create a route that matches a URL requiring an HTTP <code>PUT</code> method. We recommend using this matcher to expose actions that update database records. This method is provided as a convenience for when you really need to support the <code>PUT</code> verb; consider using the <code>patch</code> matcher instead of this one.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | — | Camel-case name of route to reference when build links and form actions (e.g., `blogPost`). |
| `pattern` | `string` | no | — | Overrides the URL pattern that will match the route. The default value is a dasherized version of `name` (e.g., a `name` of `blogPost` generates a pattern of `blog-post`). |
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
    // Route name:  ghostStory
    // Example URL: /ghosts/666/stories/616
    // Controller:  Stories
    // Action:      update
    .put(name=&quot;ghostStory&quot;, pattern=&quot;ghosts/[ghostKey]/stories/[key]&quot;, to=&quot;stories##update&quot;)

    // Route name:  goblins
    // Example URL: /goblins
    // Controller:  Goblins
    // Action:      update
    .put(name=&quot;goblins&quot;, controller=&quot;goblins&quot;, action=&quot;update&quot;)

    // Route name:  heartbeat
    // Example URL: /heartbeat
    // Controller:  Sessions
    // Action:      update
    .put(name=&quot;heartbeat&quot;, to=&quot;sessions##update&quot;)

    // Route name:  usersPreferences
    // Example URL: /preferences
    // Controller:  users.Preferences
    // Action:      update
    .put(name=&quot;preferences&quot;, to=&quot;preferences##update&quot;, package=&quot;users&quot;)

    // Route name:  orderShipment
    // Example URL: /shipments/5432
    // Controller:  orders.Shipments
    // Action:      update
    .put(
        name=&quot;shipment&quot;,
        pattern=&quot;shipments/[key]&quot;,
        to=&quot;shipments##update&quot;,
        package=&quot;orders&quot;
    )

    // Example scoping within a nested resource
    .resources(name=&quot;subscribers&quot;, nested=true)
        // Route name:  launchSubscribers
        // Example URL: /subscribers/3209/launch
        // Controller:  Subscribers
        // Action:      launch
        .put(name=&quot;launch&quot;, to=&quot;subscribers##update&quot;, on=&quot;collection&quot;)

        // Route name:  discontinueSubscriber
        // Example URL: /subscribers/2251/discontinue
        // Controller:  Subscribers
        // Action:      discontinue
        .put(name=&quot;discontinue&quot;, to=&quot;subscribers##discontinue&quot;, on=&quot;member&quot;)
    .end()
.end();

&lt;/cfscript&gt;</code></pre>
