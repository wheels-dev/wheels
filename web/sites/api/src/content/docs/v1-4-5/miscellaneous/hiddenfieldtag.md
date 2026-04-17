---
title: hiddenFieldTag()
description: "Builds and returns a string containing a hidden field form control based on the supplied name. Note: Pass any additional arguments like class, rel, and id, and"
sidebar:
  label: hiddenFieldTag()
  order: 0
---

## Signature

`hiddenFieldTag()` — returns `any`




## Description

Builds and returns a string containing a hidden field form control based on the supplied name. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for textFieldTag. |
| `value` | `string` | yes | — | See documentation for textFieldTag. |

## Examples

<pre>&lt;!--- Basic usage usually involves a `name` and `value` ---&gt;
&lt;cfoutput&gt;
    #hiddenFieldTag(name=&quot;userId&quot;, value=user.id)#
&lt;/cfoutput&gt;</pre>
