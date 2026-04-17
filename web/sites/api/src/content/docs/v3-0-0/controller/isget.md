---
title: isGet()
description: "Checks if the current HTTP request method is GET. Useful for controlling logic depending on whether a page is being displayed or data is being requested via GET"
sidebar:
  label: isGet()
  order: 0
---

## Signature

`isGet()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Checks if the current HTTP request method is GET. Useful for controlling logic depending on whether a page is being displayed or data is being requested via GET.




## Examples

<pre><code class='javascript'>component extends=&quot;Controller&quot; {

    public void function show() {
        if (isGet()) {
            // Display a form or data
            post = model(&quot;Post&quot;).findByKey(params.id);
            renderWith(action=&quot;show&quot;, data=post);
        } else {
            // Handle non-GET request (e.g., POST, DELETE)
            flashInsert(error=&quot;Invalid request method.&quot;);
            redirectTo(action=&quot;index&quot;);
        }
    }

}</code></pre>
