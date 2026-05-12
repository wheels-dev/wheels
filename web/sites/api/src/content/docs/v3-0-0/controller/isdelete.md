---
title: isDelete()
description: "Checks if the current HTTP request method is DELETE. This is useful for RESTful controllers where different logic is executed based on the request type."
sidebar:
  label: isDelete()
  order: 0
---

## Signature

`isDelete()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Checks if the current HTTP request method is DELETE. This is useful for RESTful controllers where different logic is executed based on the request type.




## Examples

<pre><code class='javascript'>component extends=&quot;Controller&quot; {

    public void function destroy() {
        if (isDelete()) {
            // Perform deletion logic
            model(&quot;Post&quot;).deleteByKey(params.id);
            flashInsert(success=&quot;Post deleted successfully.&quot;);
            redirectTo(action=&quot;index&quot;);
        } else {
            // Handle non-DELETE request
            flashInsert(error=&quot;Invalid request method.&quot;);
            redirectTo(action=&quot;index&quot;);
        }
    }

}</code></pre>
