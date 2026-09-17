---
title: isSecure()
description: "Returns whether Wheels is communicating over a secure port."
sidebar:
  label: isSecure()
  order: 0
---

## Signature

`isSecure()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Returns whether Wheels is communicating over a secure port.
<code>X-Forwarded-Proto</code> is client-controlled and is only honored when the app has opted into
proxy trust via <code>set(trustProxyHeaders=true)</code> behind a trusted reverse proxy.




## Examples

<pre><code class='javascript'>// 1. Redirect non-secure connections to the HTTPS version
if (!isSecure()) {
	redirectTo(protocol=&quot;https&quot;);
}

// 2. Conditionally set a secure cookie flag based on the connection
cookieOptions = {secure: isSecure(), httpOnly: true};

// 3. Log a warning when a sensitive action is performed over a non-secure connection
if (!isSecure()) {
	logMessage(&quot;WARNING: sensitive action performed over non-secure connection&quot;);
}
</code></pre>
