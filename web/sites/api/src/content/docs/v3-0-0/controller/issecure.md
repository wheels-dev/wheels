---
title: isSecure()
description: "Checks whether the current request is made over a secure connection (HTTPS). Returns true if the connection is secure, otherwise false."
sidebar:
  label: isSecure()
  order: 0
---

## Signature

`isSecure()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Checks whether the current request is made over a secure connection (HTTPS). Returns true if the connection is secure, otherwise false.




## Examples

<pre><code class='javascript'>1. Redirect non-secure connections to the secure version
if (!isSecure())
{
	redirectTo(protocol=&quot;https&quot;);
}</code></pre>
