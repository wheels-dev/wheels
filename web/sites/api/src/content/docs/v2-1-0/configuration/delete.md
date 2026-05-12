---
title: delete()
description: "Create a route that matches a URL requiring an HTTP <code>DELETE</code> method. We recommend using this matcher to expose actions that delete database records."
sidebar:
  label: delete()
  order: 0
---

## Signature

`delete()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Create a route that matches a URL requiring an HTTP <code>DELETE</code> method. We recommend using this matcher to expose actions that delete database records.



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
    // Route name:  articleReview
    // Example URL: /articles/987/reviews/12542
    // Controller:  Reviews
    // Action:      delete
    .delete(name=&quot;articleReview&quot;, pattern=&quot;articles/[articleKey]/reviews/[key]&quot;, to=&quot;reviews##delete&quot;)

    // Route name:  cookedBooks
    // Example URL: /cooked-books
    // Controller:  CookedBooks
    // Action:      delete
    .delete(name=&quot;cookedBooks&quot;, controller=&quot;cookedBooks&quot;, action=&quot;delete&quot;)

    // Route name:  logout
    // Example URL: /logout
    // Controller:  Sessions
    // Action:      delete
    .delete(name=&quot;logout&quot;, to=&quot;sessions##delete&quot;)

    // Route name:  clientsStatus
    // Example URL: /statuses/4918
    // Controller:  clients.Statuses
    // Action:      delete
    .delete(name=&quot;statuses&quot;, to=&quot;statuses##delete&quot;, package=&quot;clients&quot;)

    // Route name:  blogComment
    // Example URL: /comments/5432
    // Controller:  blog.Comments
    // Action:      delete
    .delete(
        name=&quot;comment&quot;,
        pattern=&quot;comments/[key]&quot;,
        to=&quot;comments##delete&quot;,
        package=&quot;blog&quot;
    )
.end();

&lt;/cfscript&gt;
</code></pre>
