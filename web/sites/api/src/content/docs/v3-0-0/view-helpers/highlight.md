---
title: highlight()
description: "Searches the given text for one or more phrases and wraps all matches in an HTML tag (default: &lt;span&gt;). This is useful for search results or emphasizing c"
sidebar:
  label: highlight()
  order: 0
---

## Signature

`highlight()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Searches the given text for one or more phrases and wraps all matches in an HTML tag (default: &lt;span&gt;). This is useful for search results or emphasizing certain keywords dynamically.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | Text to search in. |
| `phrase` | `string` | no | — | Phrase (or list of phrases) to highlight. This argument is also aliased as `phrases`. |
| `delimiter` | `string` | no | `,` | Delimiter to use when passing in multiple phrases. |
| `tag` | `string` | no | `span` | HTML tag to use to wrap the highlighted phrase(s). |
| `class` | `string` | no | `highlight` | Class to use in the tags wrapping highlighted phrase(s). |
| `encode` | `boolean` | no | `true` | Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead. |

## Examples

<pre><code class='javascript'>1. Basic usage (default &lt;span class=&quot;highlight&quot;&gt;)
#highlight(text=&quot;You searched for: Wheels&quot;, phrases=&quot;Wheels&quot;)#

// Output:
// You searched for: &lt;span class=&quot;highlight&quot;&gt;Wheels&lt;/span&gt;

2. Highlight multiple phrases
#highlight(
    text=&quot;ColdFusion and Wheels make development fun.&quot;,
    phrases=&quot;ColdFusion,Wheels&quot;
)#

// Output:
// &lt;span class=&quot;highlight&quot;&gt;ColdFusion&lt;/span&gt; and &lt;span class=&quot;highlight&quot;&gt;Wheels&lt;/span&gt; make development fun.

3. Use a custom delimiter for multiple phrases
#highlight(
    text=&quot;Apples | Oranges | Bananas&quot;,
    phrases=&quot;Apples|Bananas&quot;,
    delimiter=&quot;|&quot;
)#

// Output:
// &lt;span class=&quot;highlight&quot;&gt;Apples&lt;/span&gt; | Oranges | &lt;span class=&quot;highlight&quot;&gt;Bananas&lt;/span&gt;

4. Use a different HTML tag
#highlight(
    text=&quot;Important: Read the documentation carefully.&quot;,
    phrases=&quot;Important&quot;,
    tag=&quot;strong&quot;
)#

// Output:
// &lt;strong class=&quot;highlight&quot;&gt;Important&lt;/strong&gt;: Read the documentation carefully.
</code></pre>
