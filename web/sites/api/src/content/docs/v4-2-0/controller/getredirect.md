---
title: getRedirect()
description: "Primarily used for testing to establish whether the current request has performed a redirect."
sidebar:
  label: getRedirect()
  order: 0
---

## Signature

`getRedirect()` — returns `struct`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Primarily used for testing to establish whether the current request has performed a redirect.




## Examples

<pre><code class='javascript'>// 1. Assert that a redirect was performed to a specific URL (in a test)
processDelete();
redirect = getRedirect();
assert(&quot;structCount(redirect) gt 0&quot;);
assert(&quot;redirect.url eq '/users'&quot;);

// 2. Inspect the full redirect struct after an action runs
submitLogin();
redirect = getRedirect();
// redirect.url        -&gt; &quot;/dashboard&quot;
// redirect.statusCode -&gt; 302
// redirect.addToken   -&gt; false

// 3. Confirm no redirect was performed (action rendered a view instead)
showProfile();
redirect = getRedirect();
// redirect -&gt; {}
</code></pre>
