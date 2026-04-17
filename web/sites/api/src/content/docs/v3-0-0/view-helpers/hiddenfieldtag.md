---
title: hiddenFieldTag()
description: "Generates a hidden &lt;input type=\"hidden\"&gt; tag using a plain name/value pair. Unlike hiddenField(), this helper does not tie to a model object — it’s meant"
sidebar:
  label: hiddenFieldTag()
  order: 0
---

## Signature

`hiddenFieldTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Generates a hidden &lt;input type="hidden"&gt; tag using a plain name/value pair. Unlike hiddenField(), this helper does not tie to a model object — it’s meant for raw form fields where you control the name and value manually.
Note: Pass any additional arguments like <code>class</code>, <code>rel</code>, and <code>id</code>, and the generated tag will also include those values as HTML attributes.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `value` | `string` | no | — | Value to populate in tag's value attribute. |
| `encode` | `boolean` | no | `true` | Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead. |

## Examples

<pre><code class='javascript'>1. Basic usage
#hiddenFieldTag(name=&quot;userId&quot;, value=user.id)#

// Generates:
// &lt;input id=&quot;userId&quot; name=&quot;userId&quot; type=&quot;hidden&quot; value=&quot;123&quot;&gt;

2. With additional attributes
#hiddenFieldTag(
    name=&quot;sessionToken&quot;,
    value=&quot;abc123&quot;,
    id=&quot;token-field&quot;,
    class=&quot;hidden-tracker&quot;
)#

// &lt;input id=&quot;token-field&quot; name=&quot;sessionToken&quot; type=&quot;hidden&quot; value=&quot;abc123&quot; class=&quot;hidden-tracker&quot;&gt;

3. Without specifying a value (empty by default)
#hiddenFieldTag(name=&quot;csrfToken&quot;)#

// &lt;input id=&quot;csrfToken&quot; name=&quot;csrfToken&quot; type=&quot;hidden&quot; value=&quot;&quot;&gt;

4. Disabling encoding
#hiddenFieldTag(
    name=&quot;redirectUrl&quot;,
    value=&quot;https://example.com/?a=1&amp;b=2&quot;,
    encode=false
)#

// &lt;input id=&quot;redirectUrl&quot; name=&quot;redirectUrl&quot; type=&quot;hidden&quot; value=&quot;https://example.com/?a=1&amp;b=2&quot;&gt;
</code></pre>
