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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `datasource` | `string` | yes | — | The data source name to connect to. |
| `username` | `string` | no | — | The username for the data source. |
| `password` | `string` | no | — | The password for the data source. |

</div>

## Examples

<pre><code class='javascript'>// 1. Override the data source for a model (basic usage).
// In models/User.cfc
config() {
	// Tell Wheels to use the data source named `users_source` instead of
	// the default one whenever this model makes SQL calls.
	dataSource(&quot;users_source&quot;);
}

// 2. Override the data source with explicit credentials.
// In models/LegacyOrder.cfc
config() {
	dataSource(datasource=&quot;legacy_db&quot;, username=&quot;app_reader&quot;, password=&quot;s3cr3t&quot;);
}
</code></pre>
