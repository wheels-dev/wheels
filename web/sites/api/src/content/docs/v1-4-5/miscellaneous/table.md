---
title: table()
description: "Use this method to tell Wheels what database table to connect to for this model. You only need to use this method when your table naming does not follow the sta"
sidebar:
  label: table()
  order: 0
---

## Signature

`table()` — returns `any`




## Description

Use this method to tell Wheels what database table to connect to for this model. You only need to use this method when your table naming does not follow the standard Wheels convention of a singular object name mapping to a plural table name. To not use a table for your model at all, call table(false).

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `any` | yes | — | Name of the table to map this model to. |

## Examples

<pre>table(name) &lt;!--- In models/User.cfc ---&gt;
&lt;cffunction name=&quot;init&quot;&gt;
    &lt;!--- Tell Wheels to use the `tbl_USERS` table in the database for the `user` model instead of the default (which would be `users`) ---&gt;
    &lt;cfset table(&quot;tbl_USERS&quot;)&gt;
&lt;/cffunction&gt;</pre>
