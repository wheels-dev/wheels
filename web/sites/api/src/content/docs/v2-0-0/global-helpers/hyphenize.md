---
title: hyphenize()
description: "Converts camelCase strings to lowercase strings with hyphens as word delimiters instead. Example: myVariable becomes my-variable."
sidebar:
  label: hyphenize()
  order: 0
---

## Signature

`hyphenize()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`
**Category:** String Functions

## Description

Converts camelCase strings to lowercase strings with hyphens as word delimiters instead. Example: myVariable becomes my-variable.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `string` | `string` | yes | — | The string to hyphenize. |

## Examples

<pre>&lt;!---Outputs &quot;my-blog-post&quot; ---&gt;
#hyphenize(&quot;myBlogPost&quot;)#</pre>
