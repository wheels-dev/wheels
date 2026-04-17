---
title: truncate()
description: "Shortens a given text string to a specified length and appends a replacement string (by default \"...\") at the end to indicate truncation. It is useful for displ"
sidebar:
  label: truncate()
  order: 0
---

## Signature

`truncate()` — returns `string`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Shortens a given text string to a specified length and appends a replacement string (by default "...") at the end to indicate truncation. It is useful for displaying previews of longer text in UIs, summaries, or reports while keeping the output concise.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to truncate. |
| `length` | `numeric` | no | `30` | Length to truncate the text to. |
| `truncateString` | `string` | no | `...` | String to replace the last characters with. |

## Examples

<pre><code class='javascript'>1. Truncate text to 20 characters, default truncation string "..."
truncate(text="Wheels is a framework for ColdFusion", length=20)
/* Output: "Wheels is a fra..." */

2. Use a custom truncation string
truncate(text="Wheels is a framework for ColdFusion", truncateString=" (more)")
/* Output: "Wheels is a framework (more)" */

3. Short text does not get truncated
truncate(text="Short text", length=20)
/* Output: "Short text" */

4. Display in a view for previews
&lt;p&gt;truncate(article.content, 100)&lt;/p&gt;</code></pre>
