---
title: mapper()
description: "Returns the mapper object used to configure your application's routes. Usually you will use this method in <code>app/config/routes.cfm</code> to start chaining"
sidebar:
  label: mapper()
  order: 0
---

## Signature

`mapper()` — returns `struct`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Routing

## Description

Returns the mapper object used to configure your application's routes. Usually you will use this method in <code>app/config/routes.cfm</code> to start chaining route mapping methods like <code>resources</code>, <code>namespace</code>, etc.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `restful` | `boolean` | no | `true` | Whether to turn on RESTful routing or not. Not recommended to set. Will probably be removed in a future version of wheels, as RESTful routes are the default. |
| `methods` | `boolean` | no | `[runtime expression]` | If not RESTful, then specify allowed routes. Not recommended to set. Will probably be removed in a future version of wheels, as RESTful routes are the default. |
| `mapFormat` | `boolean` | no | `true` | This is useful for providing formats via URL like `json`, `xml`, `pdf`, etc. Set to false to disable automatic .[format] generation for resource based routes |

</div>

## Examples

<pre><code class='javascript'>1. Basic Usage
&lt;cfscript&gt;
mapper()
    .resources(&quot;posts&quot;)  // generates standard RESTful routes for posts
    .get(name=&quot;about&quot;, pattern=&quot;about-us&quot;, to=&quot;pages##about&quot;) // custom GET route
    .namespace(&quot;admin&quot;) // group routes under admin namespace
        .resources(&quot;users&quot;) // RESTful routes for admin users
    .end();
&lt;/cfscript&gt;

2. Disable format mapping
mapper(mapFormat=false)
    .resources(&quot;reports&quot;);

// This will prevent automatic generation of .json or .xml endpoints for the resource.</code></pre>
