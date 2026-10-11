---
title: resources()
description: "Create a group of routes that exposes actions for manipulating a collection of resources. A plural resource exposes URL patterns for the entire CRUD lifecycle ("
sidebar:
  label: resources()
  order: 0
---

## Signature

`resources()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Create a group of routes that exposes actions for manipulating a collection of resources. A plural resource exposes URL patterns for the entire CRUD lifecycle (<code>index</code>, <code>show</code>, <code>new</code>, <code>create</code>, <code>edit</code>, <code>update</code>, <code>delete</code>), exposing a primary key in the URL for showing, editing, updating, and deleting records. If you need to generate routes for manipulating a singular resource without a primary key, see the <code>resource</code> mapper method.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Camel-case name of resource to reference when build links and form actions. This is typically a plural word (e.g., `posts`). |
| `nested` | `boolean` | no | `false` | Whether or not additional calls will be nested within this resource. |
| `path` | `string` | no | `[runtime expression]` | Override URL path representing this resource. Default is a dasherized version of `name` (e.g., `blogPosts` generates a path of `blog-posts`). |
| `controller` | `string` | no | — | Override name of the controller used by resource. This defaults to the value provided for `name`. |
| `singular` | `string` | no | — | Override singularize() result in plural resources. |
| `plural` | `string` | no | — | Override pluralize() result in singular resource. |
| `only` | `string` | no | — | Limits the list of RESTful routes to generate. Can include `index`, `show`, `new`, `create`, `edit`, `update`, and `delete`. |
| `except` | `string` | no | — | Excludes RESTful routes to generate, taking priority over the `only` argument. Can include `index`, `show`, `new`, `create`, `edit`, `update`, and `delete`. |
| `shallow` | `boolean` | no | — | Turn on shallow resources. |
| `shallowPath` | `string` | no | — | Shallow path prefix. |
| `shallowName` | `string` | no | — | Shallow name prefix. |
| `constraints` | `struct` | no | — | Variable patterns to use for matching. |
| `callback` | `any` | no | — |  |
| `binding` | `any` | no | — |  |
| `bindBy` | `any` | no | — |  |
| `mapFormat` | `boolean` | no | `[runtime expression]` | Whether or not to add an optional `.[format]` pattern to the end of the generated routes. This is useful for providing formats via URL like `json`, `xml`, `pdf`, etc. |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    // 1. Basic CRUD resource — generates index, show, new, create, edit, update, delete routes
    .resources(&quot;admins&quot;)

    // 2. Point authors URL to controller at `app/controllers/Users.cfc`
    .resources(name=&quot;authors&quot;, controller=&quot;users&quot;)

    // 3. Limit routes to a specific set with the `only` argument
    .resources(name=&quot;products&quot;, only=&quot;index,show,edit,update&quot;)

    // 4. Exclude specific routes using the `except` argument
    .resources(name=&quot;orders&quot;, except=&quot;delete&quot;)

    // 5. Nested resources — child routes receive parent key in URL (e.g. /stories/1/heroes)
    .resources(name=&quot;stories&quot;, nested=true)
        .resources(&quot;heroes&quot;)
        .resources(&quot;villains&quot;)
    .end()

    // 6. Override the URL path (e.g. /blog-posts/options instead of /blog-posts-options)
    .resources(name=&quot;blogPostsOptions&quot;, path=&quot;blog-posts/options&quot;)

    // 7. Shallow nesting — member routes (show, edit, update, delete) drop the parent prefix
    .resources(name=&quot;posts&quot;, nested=true, shallow=true)
        .resources(&quot;comments&quot;)
    .end()

    // 8. Constrain URL parameters to a specific pattern (e.g. numeric IDs only)
    .resources(name=&quot;photos&quot;, constraints={key=&quot;[0-9]+&quot;})

    // 9. Override the singularized form when auto-detection is wrong
    .resources(name=&quot;people&quot;, singular=&quot;person&quot;)
.end();

&lt;/cfscript&gt;
</code></pre>
