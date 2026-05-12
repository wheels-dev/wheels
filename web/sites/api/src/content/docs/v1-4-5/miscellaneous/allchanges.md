---
title: allChanges()
description: "Returns a struct detailing all changes that have been made on the object but not yet saved to the database."
sidebar:
  label: allChanges()
  order: 0
---

## Signature

`allChanges()` — returns `any`




## Description

Returns a struct detailing all changes that have been made on the object but not yet saved to the database.


## Examples

<pre>allChanges() &lt;!--- Get an object, change it, and then ask for its changes (will return a struct containing the changes, both property names and their values) ---&gt;
&lt;cfset member = model(&quot;member&quot;).findByKey(params.memberId)&gt;
&lt;cfset member.firstName = params.newFirstName&gt;
&lt;cfset member.email = params.newEmail&gt;
&lt;cfset allChanges = member.allChanges()&gt;</pre>
