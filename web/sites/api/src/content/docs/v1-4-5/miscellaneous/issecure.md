---
title: isSecure()
description: "Returns whether CFWheels is communicating over a secure port."
sidebar:
  label: isSecure()
  order: 0
---

## Signature

`isSecure()` — returns `any`




## Description

Returns whether CFWheels is communicating over a secure port.


## Examples

<pre>// Redirect non-secure connections to the secure version
if (!isSecure())
{
	redirectTo(protocol=&quot;https&quot;);
}</pre>
