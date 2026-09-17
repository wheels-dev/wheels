---
title: get()
description: "Create a route that matches a URL requiring an HTTP <code>GET</code> method. We recommend only using this matcher to expose actions that display data. See <code"
sidebar:
  label: get()
  order: 0
---

## Signature

`get()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Create a route that matches a URL requiring an HTTP <code>GET</code> method. We recommend only using this matcher to expose actions that display data. See <code>post</code>, <code>patch</code>, <code>delete</code>, and <code>put</code> for matchers that are appropriate for actions that change data in your database.



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
    // 1. Basic GET route using the `to` shorthand (controller##action)
    // Route name:  post
    // Example URL: /posts/my-post-title
    // Controller:  Posts
    // Action:      show
    .get(name=&quot;post&quot;, pattern=&quot;posts/[slug]&quot;, to=&quot;posts##show&quot;)

    // 2. Route using separate `controller` and `action` arguments
    // Route name:  posts
    // Example URL: /posts
    // Controller:  Posts
    // Action:      index
    .get(name=&quot;posts&quot;, controller=&quot;posts&quot;, action=&quot;index&quot;)

    // 3. Custom URL pattern that differs from the route name
    // Route name:  authors
    // Example URL: /the-scribes
    // Controller:  Authors
    // Action:      index
    .get(name=&quot;authors&quot;, pattern=&quot;the-scribes&quot;, to=&quot;authors##index&quot;)

    // 4. Package (subfolder) scoping — keeps the package out of the URL
    // Route name:  commerceCart
    // Example URL: /cart
    // Controller:  commerce.Carts
    // Action:      show
    .get(name=&quot;cart&quot;, to=&quot;carts##show&quot;, package=&quot;commerce&quot;)

    // 5. Multi-line format for readability, with package scoping
    // Route name:  extranetEditProfile
    // Example URL: /profile/edit
    // Controller:  extranet.Profiles
    // Action:      edit
    .get(
        name=&quot;editProfile&quot;,
        pattern=&quot;profile/edit&quot;,
        to=&quot;profiles##edit&quot;,
        package=&quot;extranet&quot;
    )

    // 6. Permanent redirect — useful for renamed or moved URLs
    // Example URL: /old-about  -&gt;  302 redirect to /about
    .get(name=&quot;oldAbout&quot;, pattern=&quot;old-about&quot;, redirect=&quot;/about&quot;)

    // 7. GET routes scoped inside a nested resource
    .resources(name=&quot;users&quot;, nested=true)
        // Route name:  activatedUsers
        // Example URL: /users/activated
        // Controller:  Users
        // Action:      activated
        .get(name=&quot;activated&quot;, to=&quot;users##activated&quot;, on=&quot;collection&quot;)

        // Route name:  preferencesUser
        // Example URL: /users/391/preferences
        // Controller:  Preferences
        // Action:      index
        .get(name=&quot;preferences&quot;, to=&quot;preferences##index&quot;, on=&quot;member&quot;)
    .end()
.end();

&lt;/cfscript&gt;
</code></pre>
