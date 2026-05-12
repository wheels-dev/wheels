---
title: dataSource()
description: "dataSource() is a model configuration method used to override the default database connection for a specific model. This is useful when you want a model to quer"
sidebar:
  label: dataSource()
  order: 0
---

## Signature

`dataSource()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

dataSource() is a model configuration method used to override the default database connection for a specific model. This is useful when you want a model to query a different database or use specific credentials than the application default.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `datasource` | `string` | yes | — | The data source name to connect to. |
| `username` | `string` | no | — | The username for the data source. |
| `password` | `string` | no | — | The password for the data source. |

</div>

## Examples

<pre><code class='javascript'>// In app/models/User.cfc
component extends="Model" {

    function config() {
        // Use a custom datasource for this model
        dataSource("users_source");
        
        // Optional: specify credentials
        // dataSource("users_source", "dbUser", "dbPass");
    }
}</code></pre>
