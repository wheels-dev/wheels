---
title: getRoutes()
description: "Returns all the routes that have been defined in the application via the mapper() function. It provides a programmatic way to inspect the routing table, includi"
sidebar:
  label: getRoutes()
  order: 0
---

## Signature

`getRoutes()` — returns `any`

**Available in:** `mapper`


## Description

Returns all the routes that have been defined in the application via the mapper() function. It provides a programmatic way to inspect the routing table, including route names, URL patterns, controllers, actions, and other metadata. This is useful for debugging, generating dynamic links, or performing logic based on the routes that exist in your application.


## Examples

<pre><code class='javascript'>1. Get all defined routes
allRoutes = application.wheels.mapper.getRoutes();

// Loop through routes and display their patterns
for (var r in allRoutes) {
    writeOutput(&quot;Route name: &quot; & r.name & &quot;&lt;br&gt;&quot;);
    writeOutput(&quot;Pattern: &quot; & r.pattern & &quot;&lt;br&gt;&quot;);
    writeOutput(&quot;Controller: &quot; & r.controller & &quot;&lt;br&gt;&quot;);
    writeOutput(&quot;Action: &quot; & r.action & &quot;&lt;br&gt;&lt;br&gt;&quot;);
}
</code></pre>
