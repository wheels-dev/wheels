---
title: isHead()
description: "Checks if the current HTTP request method is HEAD. HEAD requests are similar to GET requests but do not return a message body, only the headers. This is often u"
sidebar:
  label: isHead()
  order: 0
---

## Signature

`isHead()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Checks if the current HTTP request method is HEAD. HEAD requests are similar to GET requests but do not return a message body, only the headers. This is often used for checking metadata like content length or existence without transferring the actual content.




## Examples

<pre><code class='javascript'>component extends=&quot;Controller&quot; {

    public void function checkFile() {
        if (isHead()) {
            // Respond with headers only, no content
        } else {
            // Handle normal GET or other requests
            fileData = model(&quot;File&quot;).findByKey(params.id);
            renderWith(action=&quot;show&quot;, data=fileData);
        }
    }

}</code></pre>
