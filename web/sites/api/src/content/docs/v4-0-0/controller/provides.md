---
title: provides()
description: "Defines formats that the controller will respond with upon request."
sidebar:
  label: provides()
  order: 0
---

## Signature

`provides()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Defines formats that the controller will respond with upon request.
The format can be requested through a URL variable called <code>format</code>, by appending the <code>format</code> name to the end of a URL as an extension (when URL rewriting is enabled), or in the request header.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `formats` | `string` | no | — | Formats to instruct the controller to provide. Valid values are `html` (the default), `xml`, `json`, `csv`, `pdf`, and `xls`. |

</div>

