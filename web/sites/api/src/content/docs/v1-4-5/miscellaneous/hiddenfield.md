---
title: hiddenField()
description: "Builds and returns a string containing a hidden field form control based on the supplied objectName and property. Note: Pass any additional arguments like class"
sidebar:
  label: hiddenField()
  order: 0
---

## Signature

`hiddenField()` — returns `any`




## Description

Builds and returns a string containing a hidden field form control based on the supplied objectName and property. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | See documentation for textField. |
| `property` | `string` | yes | — | See documentation for textField. |
| `association` | `string` | yes | — | See documentation for textfield. |
| `position` | `string` | yes | — | See documentation for textfield. |

## Examples

<pre>&lt;!--- Provide an `objectName` and `property` ---&gt;
&lt;cfoutput&gt;
    #hiddenField(objectName=&quot;user&quot;, property=&quot;id&quot;)#
&lt;/cfoutput&gt;</pre>
