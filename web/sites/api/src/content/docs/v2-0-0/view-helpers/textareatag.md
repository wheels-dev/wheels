---
title: textAreaTag()
description: "Builds and returns a string containing a text area form control based on the supplied name."
sidebar:
  label: textAreaTag()
  order: 0
---

## Signature

`textAreaTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a string containing a text area form control based on the supplied name.
Note: Pass any additional arguments like <code>class</code>, <code>rel</code>, and <code>id</code>, and the generated tag will also include those values as HTML attributes.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `content` | `string` | no | — | Content to display in textarea on page load. |
| `label` | `string` | no | — | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre>&lt;!--- Basic usage usually involves a `label`, `name`, and `password` ---&gt;
#textAreaTag(label=&quot;Description&quot;, name=&quot;description&quot;, content=params.description)#</pre>
