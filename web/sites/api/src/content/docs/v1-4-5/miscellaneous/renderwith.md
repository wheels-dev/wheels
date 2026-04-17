---
title: renderWith()
description: "Instructs the controller to render the data passed in to the format that is requested. If the format requested is json or xml, CFWheels will transform the data"
sidebar:
  label: renderWith()
  order: 0
---

## Signature

`renderWith()` — returns `any`




## Description

Instructs the controller to render the data passed in to the format that is requested. If the format requested is json or xml, CFWheels will transform the data into that format automatically. For other formats (or to override the automatic formatting), you can also create a view template in this format: nameofaction.xml.cfm, nameofaction.json.cfm, nameofaction.pdf.cfm, etc.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `data` | `any` | yes | — | Data to format and render. |
| `controller` | `string` | yes | — | See documentation for renderPage. |
| `action` | `string` | yes | — | See documentation for renderPage. |
| `template` | `string` | yes | — | See documentation for renderPage. |
| `layout` | `any` | yes | — | See documentation for renderPage. |
| `cache` | `any` | yes | — | See documentation for renderPage. |
| `returnAs` | `string` | yes | — | See documentation for renderPage. |
| `hideDebugInformation` | `boolean` | yes | `false` | See documentation for renderPage. |

## Examples

<pre>// This will provide the formats defined in the `init()` function
products = model(&quot;product&quot;).findAll();
renderWith(products);</pre>
