---
title: hiddenFieldTag()
description: "Builds and returns a string containing a hidden field form control based on the supplied name."
sidebar:
  label: hiddenFieldTag()
  order: 0
---

## Signature

`hiddenFieldTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a string containing a hidden field form control based on the supplied name.
Note: Pass any additional arguments like <code>class</code>, <code>rel</code>, and <code>id</code>, and the generated tag will also include those values as HTML attributes.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `value` | `string` | no | — | Value to populate in tag's value attribute. |
| `encode` | `boolean` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre>&lt;!--- Basic usage usually involves a `name` and `value` ---&gt;
#hiddenFieldTag(name=&quot;userId&quot;, value=user.id)#</pre>
