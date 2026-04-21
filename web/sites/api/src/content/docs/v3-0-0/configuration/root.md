---
title: root()
description: "Defines a route that matches the root of the current context. This could be the root of the entire application (like the home page) or the root of a namespaced"
sidebar:
  label: root()
  order: 0
---

## Signature

`root()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Defines a route that matches the root of the current context. This could be the root of the entire application (like the home page) or the root of a namespaced section of your routes. It is commonly used to map a controller action to the main entry point of your application or a subsection of it. You can specify the controller and action either using the to argument (controller##action) or by passing controller and action separately. Optionally, mapFormat can be set to true to allow a format suffix like .json or .xml in the URL.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `to` | `string` | no | — | Set `controller##action` combination to map the route to. You may use either this argument or a combination of `controller` and `action`. |
| `mapFormat` | `boolean` | no | — | Set to `true` to include the format (e.g. `.json`) in the route. |

</div>

## Examples

<pre><code class='javascript'>1. Application Home Page
Map the root of the application (/) to a controller action:

&lt;cfscript&gt;
mapper()
    .root(to=&quot;dashboards##show&quot;)
.end();
&lt;/cfscript&gt;

2. Root of a Namespaced Section (API)
Map /api to an API controller:

&lt;cfscript&gt;
mapper()
    .namespace(&quot;api&quot;)
        .root(controller=&quot;apis&quot;, action=&quot;index&quot;)
    .end();
&lt;/cfscript&gt;

3. Root with Optional Format
Enable clients to request JSON or XML directly:

&lt;cfscript&gt;
mapper()
    .namespace(&quot;api&quot;)
        .root(controller=&quot;apis&quot;, action=&quot;index&quot;, mapFormat=true)
    .end();
&lt;/cfscript&gt;

4. Root for Nested Resources
Use root() inside a nested scope:

&lt;cfscript&gt;
mapper()
    .namespace(&quot;admin&quot;)
        .root(controller=&quot;dashboard&quot;, action=&quot;index&quot;)
    .end();
.end();
&lt;/cfscript&gt;
</code></pre>
