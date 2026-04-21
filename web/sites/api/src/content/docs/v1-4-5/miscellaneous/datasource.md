---
title: dataSource()
description: "Use this method to override the data source connection information for this model."
sidebar:
  label: dataSource()
  order: 0
---

## Signature

`dataSource()` — returns `any`




## Description

Use this method to override the data source connection information for this model.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `datasource` | `string` | yes | — | The data source name to connect to. |
| `username` | `string` | yes | — | The username for the data source. |
| `password` | `string` | yes | — | The password for the data source. |

</div>

## Examples

<pre>dataSource(datasource [, username, password ]) &lt;!--- In models/User.cfc ---&gt;
&lt;cffunction name=&quot;init&quot;&gt;
    &lt;!--- Tell Wheels to use the data source named `users_source` instead of the default one whenever this model makes SQL calls  ---&gt;
              &lt;cfset dataSource(&quot;users_source&quot;)&gt;
&lt;/cffunction&gt;</pre>
