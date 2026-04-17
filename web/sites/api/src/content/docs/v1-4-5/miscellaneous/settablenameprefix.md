---
title: setTableNamePrefix()
description: "Sets a prefix to prepend to the table name when this model runs SQL queries."
sidebar:
  label: setTableNamePrefix()
  order: 0
---

## Signature

`setTableNamePrefix()` — returns `any`




## Description

Sets a prefix to prepend to the table name when this model runs SQL queries.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `prefix` | `string` | yes | — | A prefix to prepend to the table name. |

## Examples

<pre>setTableNamePrefix(prefix) &lt;!--- In `models/User.cfc`, add a prefix to the default table name of `tbl` ---&gt;
&lt;cffunction name=&quot;init&quot;&gt;
    &lt;cfset setTableNamePrefix(&quot;tbl&quot;)&gt;
&lt;/cffunction&gt;</pre>
