---
title: hyphenize()
description: "Converts camelCase or PascalCase strings into lowercase hyphen-separated strings. Useful for generating URL-friendly slugs, CSS class names, or readable identif"
sidebar:
  label: hyphenize()
  order: 0
---

## Signature

`hyphenize()` — returns `string`

**Available in:** `controller`, `model`, `test`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Converts camelCase or PascalCase strings into lowercase hyphen-separated strings. Useful for generating URL-friendly slugs, CSS class names, or readable identifiers.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `string` | `string` | yes | — | The string to hyphenize. |

</div>

## Examples

<pre><code class='javascript'>1. Basic camelCase string
#hyphenize(&quot;myBlogPost&quot;)#

// Output:
// my-blog-post

2. PascalCase string
#hyphenize(&quot;UserProfileSettings&quot;)#

// Output:
// user-profile-settings

3. Single word (no change)
#hyphenize(&quot;Dashboard&quot;)#

// Output:
// dashboard

4. Already hyphenated string (stays lowercase)
#hyphenize(&quot;already-hyphenized&quot;)#

// Output:
// already-hyphenized
</code></pre>
