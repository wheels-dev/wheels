---
title: api()
description: "Scope routes under an API path prefix. Shorthand for <code>.group(path=\"api\", name=\"api\", ...)</code>. Typically used in combination with <code>version()</code>"
sidebar:
  label: api()
  order: 0
---

## Signature

`api()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Scope routes under an API path prefix. Shorthand for <code>.group(path="api", name="api", ...)</code>. Typically used in combination with <code>version()</code> to organize versioned API endpoints.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `path` | `string` | no | `api` | URL path prefix for the API. Defaults to `"api"`. |
| `name` | `string` | no | `api` | Name prefix for route names. Defaults to `"api"`. |
| `constraints` | `struct` | no | — | Variable patterns to apply to all child routes. |
| `callback` | `any` | no | — | A callback function to define nested routes within this API scope. |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

// 1. Basic API scope using the default path and name prefix &quot;api&quot;
mapper()
    .api()
        // Route name:  apiUsers
        // Example URL: /api/users
        .resources(&quot;users&quot;)
    .end()
.end();

// 2. Combine api() with version() for versioned API endpoints
mapper()
    .api()
        .version(1)
            // Route name:  apiV1Users
            // Example URL: /api/v1/users
            .resources(&quot;users&quot;)
        .end()

        .version(2)
            // Route name:  apiV2Products
            // Example URL: /api/v2/products
            .resources(&quot;products&quot;)
        .end()
    .end()
.end();

// 3. Override the default path and name prefixes
mapper()
    .api(path=&quot;public-api&quot;, name=&quot;publicApi&quot;)
        // Route name:  publicApiOrders
        // Example URL: /public-api/orders
        .resources(&quot;orders&quot;)
    .end()
.end();

// 4. Use api() with a callback to avoid manual .end() calls
mapper()
    .api(callback=function(m) {
        m.version(number=1, callback=function(m) {
            // Route name:  apiV1Users
            // Example URL: /api/v1/users
            m.resources(&quot;users&quot;);
        });
    })
.end();

&lt;/cfscript&gt;
</code></pre>
