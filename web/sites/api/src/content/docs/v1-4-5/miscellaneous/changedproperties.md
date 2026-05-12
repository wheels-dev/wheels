---
title: changedProperties()
description: "Returns a list of the object properties that have been changed but not yet saved to the database."
sidebar:
  label: changedProperties()
  order: 0
---

## Signature

`changedProperties()` — returns `any`




## Description

Returns a list of the object properties that have been changed but not yet saved to the database.


## Examples

<pre>changedProperties() &lt;!--- Get an object, change it, and then ask for its changes (will return a list of the property names that have changed, not the values themselves) ---&gt;
&lt;cfset member = model(&quot;member&quot;).findByKey(params.memberId)&gt;
&lt;cfset member.firstName = params.newFirstName&gt;
&lt;cfset member.email = params.newEmail&gt;
&lt;cfset changedProperties = member.changedProperties()&gt;</pre>
