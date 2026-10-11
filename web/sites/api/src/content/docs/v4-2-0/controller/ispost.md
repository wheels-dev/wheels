---
title: isPost()
description: "Returns whether the request came from a form <code>POST</code> submission or not."
sidebar:
  label: isPost()
  order: 0
---

## Signature

`isPost()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Returns whether the request came from a form <code>POST</code> submission or not.




## Examples

<pre><code class='javascript'>// 1. Respond differently depending on whether the request is a POST
if (isPost()) {
    // Process the submitted form data
    user = model(&quot;User&quot;).new(params.user);
    if (user.save()) {
        redirectTo(action=&quot;index&quot;);
    } else {
        renderView(action=&quot;new&quot;);
    }
} else {
    renderView(action=&quot;new&quot;);
}

// 2. Guard an action so it only accepts POST requests
function create() {
    if (!isPost()) {
        renderNothing(status=&quot;405 Method Not Allowed&quot;);
        return;
    }
    // handle form submission
}

// 3. Store the result for later use in the action
requestIsPost = isPost();
// requestIsPost -&gt; true (when submitted via a form POST)
// requestIsPost -&gt; false (when the page is visited normally with GET)
</code></pre>
