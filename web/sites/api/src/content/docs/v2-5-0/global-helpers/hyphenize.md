---
title: hyphenize()
description: "Converts camelCase strings to lowercase strings with hyphens as word delimiters instead. Example: myVariable becomes my-variable."
sidebar:
  label: hyphenize()
  order: 0
---

## Signature

`hyphenize()` — returns `string`

**Available in:** `controller`, `model`, `test`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Converts camelCase strings to lowercase strings with hyphens as word delimiters instead. Example: myVariable becomes my-variable.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `string` | `string` | yes | — | The string to hyphenize. |

</div>

## Examples

<pre><code class='javascript'>&lt;!---Outputs &quot;my-blog-post&quot; ---&gt;
#hyphenize(&quot;myBlogPost&quot;)#</code></pre>
