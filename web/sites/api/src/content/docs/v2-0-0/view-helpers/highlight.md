---
title: highlight()
description: "Highlights the phrase(s) everywhere in the text if found by wrapping them in <code>span</code> tags."
sidebar:
  label: highlight()
  order: 0
---

## Signature

`highlight()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Highlights the phrase(s) everywhere in the text if found by wrapping them in <code>span</code> tags.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | Text to search in. |
| `phrase` | `string` | no | — | Phrase (or list of phrases) to highlight. This argument is also aliased as `phrases`. |
| `delimiter` | `string` | no | `,` | Delimiter to use when passing in multiple phrases. |
| `tag` | `string` | no | `span` | HTML tag to use to wrap the highlighted phrase(s). |
| `class` | `string` | no | `highlight` | Class to use in the tags wrapping highlighted phrase(s). |
| `encode` | `boolean` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre>&lt;!--- Will output: You searched for: &lt;span class=&quot;highlight&quot;&gt;CFWheels ---&gt;
#highlight(text=&quot;You searched for: CFWheels&quot;, phrases=&quot;CFWheels&quot;)#</pre>
