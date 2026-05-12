---
title: setPrimaryKeys()
description: "Alias for setPrimaryKey(). Use this for better readability when you're setting multiple properties as the primary key."
sidebar:
  label: setPrimaryKeys()
  order: 0
---

## Signature

`setPrimaryKeys()` — returns `any`




## Description

Alias for setPrimaryKey(). Use this for better readability when you're setting multiple properties as the primary key.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Property (or list of properties) to set as the primary key. |

</div>

## Examples

<pre>setPrimaryKeys(property) &lt;!--- In `models/Subscription.cfc`, define the primary key as composite of the columns `customerId` and `publicationId` ---&gt;
&lt;cffunction name=&quot;init&quot;&gt;
    &lt;cfset setPrimaryKeys(&quot;customerId,publicationId&quot;)&gt;
&lt;/cffunction&gt;</pre>
