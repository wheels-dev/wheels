---
title: compareTo()
description: "Pass in another Wheels model object to see if the two objects are the same."
sidebar:
  label: compareTo()
  order: 0
---

## Signature

`compareTo()` — returns `any`




## Description

Pass in another Wheels model object to see if the two objects are the same.


## Examples

<pre>compareTo() &lt;!--- Load a user requested in the URL/form and restrict access if it doesn't match the user stored in the session ---&gt;
&lt;cfset user = model(&quot;user&quot;).findByKey(params.key)&gt;
&lt;cfif not user.compareTo(session.user)&gt;
    &lt;cfset renderPage(action=&quot;accessDenied&quot;)&gt;
&lt;/cfif&gt;</pre>
