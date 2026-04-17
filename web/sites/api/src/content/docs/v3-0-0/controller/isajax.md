---
title: isAjax()
description: "Checks if the current request was made via JavaScript (AJAX) rather than a standard browser page load. This is useful when you want to return JSON or partial co"
sidebar:
  label: isAjax()
  order: 0
---

## Signature

`isAjax()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Checks if the current request was made via JavaScript (AJAX) rather than a standard browser page load. This is useful when you want to return JSON or partial content instead of a full HTML page.




## Examples

<pre><code class='javascript'>1. Simple conditional logic
if(isAjax()){
    // Return JSON response for AJAX requests
    cfcontent(type=&quot;application/json&quot;)
    renderWith(data={ success = true, message = &quot;This is an AJAX request&quot; });
} else {
    // Render full HTML page for normal requests
}

2. Example in a Controller Action
component extends=&quot;Controller&quot; {

    function checkStatus() {
        if (isAjax()) {
            renderWith(data={ success = true, message = &quot;This is an AJAX request&quot; });
        } else {
            flashInsert(msg=&quot;Page loaded normally&quot;);
            redirectTo(&quot;home&quot;);
        }
    }

}</code></pre>
