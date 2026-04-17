---
title: highlight()
description: "Highlights the phrase(s) everywhere in the text if found by wrapping it in a span tag."
sidebar:
  label: highlight()
  order: 0
---

## Signature

`highlight()` — returns `any`




## Description

Highlights the phrase(s) everywhere in the text if found by wrapping it in a span tag.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | Text to search. |
| `phrases` | `string` | yes | — | List of phrases to highlight. |
| `delimiter` | `string` | yes | `,` | Delimiter to use in phrases argument. |
| `tag` | `string` | yes | `span` | HTML tag to use to wrap the highlighted phrase(s). |
| `class` | `string` | yes | `highlight` | Class to use in the tags wrapping highlighted phrase(s). |

## Examples

<pre>#highlight(text=&quot;You searched for: Wheels&quot;, phrases=&quot;Wheels&quot;)#
-&gt; You searched for: &lt;span class=&quot;highlight&quot;&gt;Wheels&lt;/span&gt;</pre>
