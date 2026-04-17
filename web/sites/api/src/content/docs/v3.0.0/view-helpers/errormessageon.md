---
title: errorMessageOn()
description: "Returns the error message, if one exists, on the object's property."
sidebar:
  label: errorMessageOn()
  order: 0
---

## Signature

`errorMessageOn()` — returns `string`

**Available in:** `controller`
**Category:** Error Functions

## Description

Returns the error message, if one exists, on the object's property.
If multiple error messages exist, the first one is returned. If no error exists, it returns an empty string.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `string` | yes | — | The variable name of the object to display the error message for. |
| `property` | `string` | yes | — | The name of the property to display the error message for. |
| `prependText` | `string` | no | — | String to prepend to the error message. |
| `appendText` | `string` | no | — | String to append to the error message. |
| `wrapperElement` | `string` | no | `span` | HTML element to wrap the error message in. |
| `class` | `string` | no | `error-message` | CSS `class` to set on the wrapper element. |
| `encode` | `boolean` | no | `true` | Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead. |

## Examples

<pre><code class='javascript'>Example 1 — Basic usage
&lt;cfoutput&gt;
#errorMessageOn(objectName=&quot;author&quot;, property=&quot;email&quot;)#
&lt;/cfoutput&gt;

Displays the first error message for the email property of the author object.

Default wrapper is &lt;span class=&quot;error-message&quot;&gt;.

Example 2 — Custom wrapper and class
&lt;cfoutput&gt;
#errorMessageOn(
 objectName=&quot;author&quot;,
 property=&quot;email&quot;,
 wrapperElement=&quot;div&quot;,
 class=&quot;alert alert-danger&quot;
)#
&lt;/cfoutput&gt;

Wraps the error in a &lt;div&gt; instead of &lt;span&gt;.

Uses Bootstrap classes for styling.

Example 3 — Prepend or append text
&lt;cfoutput&gt;
#errorMessageOn(
 objectName=&quot;author&quot;,
 property=&quot;email&quot;,
 prependText=&quot;Error: &quot;,
 appendText=&quot; Please fix it.&quot;
)#
&lt;/cfoutput&gt;

Prepends &quot;Error: &quot; and appends &quot; Please fix it.&quot; around the actual error message.

Example 4 — With HTML encoding disabled
&lt;cfoutput&gt;
#errorMessageOn(
 objectName=&quot;author&quot;,
 property=&quot;email&quot;,
 encode=false
)#
&lt;/cfoutput&gt;

Output is not encoded, which can be useful if you want to include HTML formatting inside the error message itself.
</code></pre>
