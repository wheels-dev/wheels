---
title: hyphenize()
description: "Converts camelCase strings to lowercase strings with hyphens as word delimiters instead. Example: myVariable becomes my-variable."
sidebar:
  label: hyphenize()
  order: 0
---

## Signature

`hyphenize()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
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

<pre><code class='javascript'>// 1. Basic camelCase to hyphenated string
result = hyphenize(&quot;myBlogPost&quot;);
// result -&gt; &quot;my-blog-post&quot;

// 2. Single word (no change)
result = hyphenize(&quot;hello&quot;);
// result -&gt; &quot;hello&quot;

// 3. Used in URL slug generation
slug = hyphenize(&quot;userProfileSettings&quot;);
// slug -&gt; &quot;user-profile-settings&quot;
</code></pre>
