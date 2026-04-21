---
title: protectedProperties()
description: "Use this method to specify which properties cannot be set through mass assignment."
sidebar:
  label: protectedProperties()
  order: 0
---

## Signature

`protectedProperties()` — returns `any`




## Description

Use this method to specify which properties cannot be set through mass assignment.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | yes | — | Property name (or list of property names) that are not allowed to be altered through mass assignment. |

</div>

## Examples

<pre>protectedProperties([ properties ]) &lt;!--- In `models/User.cfc`, `firstName` and `lastName` cannot be changed through mass assignment operations like `updateAll()` ---&gt;
&lt;cffunction name=&quot;init&quot;&gt;
    &lt;cfset protectedProperties(&quot;firstName,lastName&quot;)&gt;
&lt;/cffunction&gt;</pre>
