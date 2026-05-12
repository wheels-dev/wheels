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
| `mapFormat` | `boolean` | no | `[runtime expression]` | Whether or not to add an optional `.[format]` pattern to the end of the generated routes. This is useful for providing formats via URL like `json`, `xml`, `pdf`, etc. |

</div>

