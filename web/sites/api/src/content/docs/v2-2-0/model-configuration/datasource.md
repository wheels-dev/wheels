---
title: dataSource()
description: "Use this method to override the data source connection information for this model."
sidebar:
  label: dataSource()
  order: 0
---

## Signature

`dataSource()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Use this method to override the data source connection information for this model.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `datasource` | `string` | yes | — | The data source name to connect to. |
| `username` | `string` | no | — | The username for the data source. |
| `password` | `string` | no | — | The password for the data source. |

## Examples

<pre><code class='javascript'>// In models/User.cfc.
config() {
	// Tell Wheels to use the data source named `users_source` instead of the default one whenever this model makes SQL calls.
	dataSource(&quot;users_source&quot;);
}</code></pre>
