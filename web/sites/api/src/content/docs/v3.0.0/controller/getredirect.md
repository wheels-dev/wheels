---
title: getRedirect()
description: "Primarily used in testing scenarios to determine whether the current request has performed a redirect. It returns a structure containing information about the r"
sidebar:
  label: getRedirect()
  order: 0
---

## Signature

`getRedirect()` — returns `struct`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Primarily used in testing scenarios to determine whether the current request has performed a redirect. It returns a structure containing information about the redirect, such as the target URL and the HTTP status code. This allows you to verify redirect behavior in automated tests without actually sending the user to another page.




## Examples

<pre><code class='javascript'>1. Get redirect information for the current request
redirectInfo = getRedirect();

// Check if a redirect occurred
if (structKeyExists(redirectInfo, &quot;url&quot;)) {
    writeOutput(&quot;Redirected to: &quot; & redirectInfo.url);
    writeOutput(&quot;HTTP status: &quot; & redirectInfo.status);
} else {
    writeOutput(&quot;No redirect occurred.&quot;);
}
</code></pre>
