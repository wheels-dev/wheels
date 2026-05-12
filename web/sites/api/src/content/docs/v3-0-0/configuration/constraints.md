---
title: constraints()
description: "Defines variable patterns for route parameters when setting up routes using the Wheels mapper(). This allows you to restrict the values that route parameters ca"
sidebar:
  label: constraints()
  order: 0
---

## Signature

`constraints()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Defines variable patterns for route parameters when setting up routes using the Wheels mapper(). This allows you to restrict the values that route parameters can take, such as limiting an id parameter to numbers only or enforcing a specific string format.




## Examples

<pre><code class='javascript'>1. Constrain a route parameter to digits only
mapper()
    .resources(name="users", nested=true)
        .member(id=":userId")
            .constraints({ userId="^\d+$" })
        .end()
    .end()
.end();

Here, the userId parameter must be a number, otherwise the route won’t match.

2. Constrain multiple parameters
mapper()
    .resources(name="orders", nested=true)
        .member(orderId=":orderId", itemId=":itemId")
            .constraints({ 
                orderId="^\d+$", 
                itemId="^\d{3}-[A-Z]{2}$" 
            })
        .end()
    .end()
.end();</code></pre>
