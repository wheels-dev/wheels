---
title: setPrimaryKey()
description: "Allows you to pass in the name(s) of the property(s) that should be used as the primary key(s). Pass as a list if defining a composite primary key. Also aliased"
sidebar:
  label: setPrimaryKey()
  order: 0
---

## Signature

`setPrimaryKey()` — returns `any`




## Description

Allows you to pass in the name(s) of the property(s) that should be used as the primary key(s). Pass as a list if defining a composite primary key. Also aliased as setPrimaryKeys().

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Property (or list of properties) to set as the primary key. |

## Examples

<pre>setPrimaryKey(property) &lt;!--- In `models/User.cfc`, define the primary key as a column called `userID` ---&gt;
&lt;cffunction name=&quot;init&quot;&gt;
    &lt;cfset setPrimaryKey(&quot;userID&quot;)&gt;
&lt;/cffunction&gt;</pre>
