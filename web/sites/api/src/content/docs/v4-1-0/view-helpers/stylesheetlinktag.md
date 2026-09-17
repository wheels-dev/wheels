---
title: styleSheetLinkTag()
description: "Returns a <code>link</code> tag for a stylesheet (or several) based on the supplied arguments."
sidebar:
  label: styleSheetLinkTag()
  order: 0
---

## Signature

`styleSheetLinkTag()` — returns `string`

**Available in:** `controller`
**Category:** Asset Functions

## Description

Returns a <code>link</code> tag for a stylesheet (or several) based on the supplied arguments.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `sources` | `string` | no | — | The name of one or many CSS files in the stylesheets folder, minus the `.css` extension. Pass a full URL to generate a tag for an external style sheet. Can also be called with the `source` argument. |
| `type` | `string` | no | `text/css` | The `type` attribute for the `link` tag. |
| `media` | `string` | no | `all` | The `media` attribute for the `link` tag. |
| `rel` | `string` | no | — | The `rel` attribute for the relation between the tag and href. |
| `head` | `boolean` | no | `false` | Set to `true` to place the output in the `head` area of the HTML page instead of the default behavior (which is to place the output where the function is called from). |
| `delim` | `string` | no | `,` | The delimiter to use for the list of CSS files. |
| `encode` | `boolean` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>// 1. Include a single stylesheet from the `stylesheets` folder
// Generates: &lt;link rel=&quot;stylesheet&quot; href=&quot;/stylesheets/app.css&quot; ...&gt;
writeOutput(styleSheetLinkTag(&quot;app&quot;));

// 2. Include multiple stylesheets with a comma-delimited list
// Generates two separate &lt;link&gt; tags for blog.css and comments.css
writeOutput(styleSheetLinkTag(&quot;blog,comments&quot;));

// 3. Include a stylesheet for print media only
writeOutput(styleSheetLinkTag(sources=&quot;print&quot;, media=&quot;print&quot;));

// 4. Include an external stylesheet via full URL
writeOutput(styleSheetLinkTag(&quot;https://fonts.googleapis.com/css2?family=Roboto&quot;));

// 5. Push a stylesheet into the &lt;head&gt; from anywhere in the view
// The tag is injected into the &lt;head&gt; section rather than rendered inline
writeOutput(styleSheetLinkTag(sources=&quot;tabs&quot;, head=true));

// 6. Use a pipe delimiter instead of the default comma
writeOutput(styleSheetLinkTag(sources=&quot;reset|layout|theme&quot;, delim=&quot;|&quot;));
</code></pre>
