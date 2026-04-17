---
title: hyphenize()
description: "Converts camelCase strings to lowercase strings with hyphens as word delimiters instead. Example: myVariable becomes my-variable."
sidebar:
  label: hyphenize()
  order: 0
---

## Signature

`hyphenize()` — returns `any`




## Description

Converts camelCase strings to lowercase strings with hyphens as word delimiters instead. Example: myVariable becomes my-variable.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `string` | `string` | yes | — | The string to hyphenize. |

## Examples

<pre>hyphenize(string) &lt;!--- Outputs &quot;my-blog-post&quot; ---&gt;
&lt;cfoutput&gt;
    #hyphenize(&quot;myBlogPost&quot;)#
&lt;/cfoutput&gt;</pre>
