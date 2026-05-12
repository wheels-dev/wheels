---
title: addRoute()
description: "Adds a new route to your application."
sidebar:
  label: addRoute()
  order: 0
---

## Signature

`addRoute()` — returns `any`




## Description

Adds a new route to your application.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name for the route. This is referenced as the name argument in functions based on URLFor() like linkTo(), startFormTag(), etc. |
| `pattern` | `string` | yes | — | The URL pattern that the route will match. |
| `controller` | `string` | yes | — | Controller to call when route matches (unless the controller name exists in the pattern). |
| `action` | `string` | yes | — | Action to call when route matches (unless the action name exists in the pattern). |

</div>

## Examples

<pre>&lt;!--- Example 1: Adds a route which will invoke the `profile` action on the `user` controller with `params.userName` set when the URL matches the `pattern` argument ---&gt;
&lt;cfset addRoute(name=&quot;userProfile&quot;, pattern=&quot;user/[username]&quot;, controller=&quot;user&quot;, action=&quot;profile&quot;)&gt;

&lt;!--- Example 2: Category/product URLs. Note the order of precedence is such that the more specific route should be defined first so Wheels will fall back to the less-specific version if it's not found ---&gt;
&lt;cfset addRoute(name=&quot;product&quot;, pattern=&quot;products/[categorySlug]/[productSlug]&quot;, controller=&quot;products&quot;, action=&quot;product&quot;)&gt;
&lt;cfset addRoute(name=&quot;productCategory&quot;, pattern=&quot;products/[categorySlug]&quot;, controller=&quot;products&quot;, action=&quot;category&quot;)&gt;
&lt;cfset addRoute(name=&quot;products&quot;, pattern=&quot;products&quot;, controller=&quot;products&quot;, action=&quot;index&quot;)&gt;

&lt;!--- Example 3: Change the `home` route. This should be listed last because it is least specific ---&gt;
&lt;cfset addRoute(name=&quot;home&quot;, pattern=&quot;&quot;, controller=&quot;main&quot;, action=&quot;index&quot;)&gt;</pre>
