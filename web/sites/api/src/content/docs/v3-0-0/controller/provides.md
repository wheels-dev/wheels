---
title: provides()
description: "The `provides()` function defines the response formats that a controller can return. Clients can request a specific format in three ways: by using a URL paramet"
sidebar:
  label: provides()
  order: 0
---

## Signature

`provides()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

The `provides()` function defines the response formats that a controller can return. Clients can request a specific format in three ways: by using a URL parameter called `format` (e.g., `?format=json`), by appending the format as an extension to the URL (e.g., `/users/1.json`) when URL rewriting is enabled, or by specifying the desired format in the `Accept` header of the HTTP request. By defining the supported formats, you ensure that your controller can automatically render the response in the requested format, such as HTML, JSON, XML, CSV, PDF, or XLS. If no format is requested or supported, the controller defaults to HTML.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `formats` | `string` | no | — | Formats to instruct the controller to provide. Valid values are `html` (the default), `xml`, `json`, `csv`, `pdf`, and `xls`. |

## Examples

<pre><code class='javascript'>1. Provide HTML, XML, and JSON responses
function config() {
    provides(&quot;html,xml,json&quot;);
}

2. Provide only JSON and CSV
function config() {
    provides(&quot;json,csv&quot;);
}

3. Default behavior (HTML only)
function config() {
    provides(); // equivalent to provides(&quot;html&quot;)
}

4. Handling requested format in the action
function show() {
    // Wheels automatically detects the requested format and renders accordingly
    renderwith(data=model(&quot;user&quot;).findByKey(params.id));
}
</code></pre>
