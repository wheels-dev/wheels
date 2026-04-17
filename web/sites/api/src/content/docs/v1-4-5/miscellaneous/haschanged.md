---
title: hasChanged()
description: "Returns true if the specified property (or any if none was passed in) has been changed but not yet saved to the database. Will also return true if the object is"
sidebar:
  label: hasChanged()
  order: 0
---

## Signature

`hasChanged()` — returns `any`




## Description

Returns true if the specified property (or any if none was passed in) has been changed but not yet saved to the database. Will also return true if the object is new and no record for it exists in the database.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to check for change. |

## Examples

<pre>hasChanged([ property ]) &lt;!--- Get a member object and change the `email` property on it ---&gt;
&lt;cfset member = model(&quot;member&quot;).findByKey(params.memberId)&gt;
&lt;cfset member.email = params.newEmail&gt;

&lt;!--- Check if the `email` property has changed ---&gt;
&lt;cfif member.hasChanged(&quot;email&quot;)&gt;
    &lt;!--- Do something... ---&gt;
&lt;/cfif&gt;

&lt;!--- The above can also be done using a dynamic function like this ---&gt;
&lt;cfif member.emailHasChanged()&gt;
    &lt;!--- Do something... ---&gt;
&lt;/cfif&gt;</pre>
