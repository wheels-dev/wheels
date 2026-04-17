---
title: changedFrom()
description: "Returns the previous value of a property that has changed. Returns an empty string if no previous value exists. Wheels will keep a note of the previous property"
sidebar:
  label: changedFrom()
  order: 0
---

## Signature

`changedFrom()` — returns `any`




## Description

Returns the previous value of a property that has changed. Returns an empty string if no previous value exists. Wheels will keep a note of the previous property value until the object is saved to the database.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to get the previous value for. |

## Examples

<pre>changedFrom(property) &lt;!--- Get a member object and change the `email` property on it ---&gt;
&lt;cfset member = model(&quot;member&quot;).findByKey(params.memberId)&gt;
&lt;cfset member.email = params.newEmail&gt;

&lt;!--- Get the previous value (what the `email` property was before it was changed)---&gt;
&lt;cfset oldValue = member.changedFrom(&quot;email&quot;)&gt;

&lt;!--- The above can also be done using a dynamic function like this ---&gt;
&lt;cfset oldValue = member.emailChangedFrom()&gt;</pre>
