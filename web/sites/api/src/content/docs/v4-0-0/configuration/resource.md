---
title: resource()
description: "Create a group of routes that exposes actions for manipulating a singular resource. A singular resource exposes URL patterns for the entire CRUD lifecycle of a"
sidebar:
  label: resource()
  order: 0
---

## Signature

`resource()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Create a group of routes that exposes actions for manipulating a singular resource. A singular resource exposes URL patterns for the entire CRUD lifecycle of a single entity (<code>show</code>, <code>new</code>, <code>create</code>, <code>edit</code>, <code>update</code>, and <code>delete</code>) without exposing a primary key in the URL. Usually this type of resource represents a singleton entity tied to the session, application, or another resource (perhaps nested within another resource). If you need to generate routes for manipulating a collection of resources with a primary key in the URL, see the <code>resources</code> mapper method.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Camel-case name of resource to reference when build links and form actions. This is typically a singular word (e.g., `profile`). |
| `nested` | `boolean` | no | `false` | Whether or not additional calls will be nested within this resource. |
| `path` | `string` | no | `[runtime expression]` | Override URL path representing this resource. Default is a dasherized version of `name` (e.g., `blogPost` generates a path of `blog-post`). |
| `controller` | `string` | no | — | Override name of the controller used by resource. This defaults to a pluralized version of `name`. |
| `singular` | `string` | no | — | Override singularize() result in plural resources. |
| `plural` | `string` | no | — | Override pluralize() result in singular resource. |
| `only` | `string` | no | — | Limits the list of RESTful routes to generate. Can include `show`, `new`, `create`, `edit`, `update`, and `delete`. |
| `except` | `string` | no | — | Excludes RESTful routes to generate, taking priority over the `only` argument. Can include `show`, `new`, `create`, `edit,` `update`, and `delete`. |
| `shallow` | `boolean` | no | — | Turn on shallow resources. |
| `shallowPath` | `string` | no | — | Shallow path prefix. |
| `shallowName` | `string` | no | — | Shallow name prefix. |
| `constraints` | `struct` | no | — | Variable patterns to use for matching. |
| `callback` | `any` | no | — |  |
| `binding` | `any` | no | — |  |
| `$call` | `string` | no | `resource` |  |
| `$plural` | `boolean` | no | `false` |  |
| `mapFormat` | `boolean` | no | `[runtime expression]` | Whether or not to add an optional `.[format]` pattern to the end of the generated routes. This is useful for providing formats via URL like `json`, `xml`, `pdf`, etc. |

</div>

