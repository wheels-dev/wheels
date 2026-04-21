---
title: accessibleProperties()
description: "Use this method to specify which properties can be set through mass assignment."
sidebar:
  label: accessibleProperties()
  order: 0
---

## Signature

`accessibleProperties()` — returns `any`




## Description

Use this method to specify which properties can be set through mass assignment.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | yes | — | Property name (or list of property names) that are allowed to be altered through mass assignment. |

</div>

## Examples

<pre>accessibleProperties([ properties ]) &lt;!--- In `models/User.cfc`, only `isActive` can be set through mass assignment operations like `updateAll()` ---&gt;
&lt;cffunction name=&quot;init&quot;&gt;
    &lt;cfset accessibleProperties(&quot;isActive&quot;)&gt;
&lt;/cffunction&gt;</pre>
