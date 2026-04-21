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

<pre><code class='javascript'>&lt;!--- view code ---&gt;
&lt;head&gt;
    &lt;!--- Includes `stylesheets/styles.css` ---&gt;
    #styleSheetLinkTag(&quot;styles&quot;)#
    &lt;!--- Includes `stylesheets/blog.css` and `stylesheets/comments.css` ---&gt;
    #styleSheetLinkTag(&quot;blog,comments&quot;)#
    &lt;!--- Includes printer style sheet ---&gt;
    #styleSheetLinkTag(sources=&quot;print&quot;, media=&quot;print&quot;)#
    &lt;!--- Includes external style sheet ---&gt;
    #styleSheetLinkTag(&quot;http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.0/themes/cupertino/jquery-ui.css&quot;)#
&lt;/head&gt;

&lt;body&gt;
    &lt;!--- This will still appear in the `head` ---&gt;
    #styleSheetLinkTag(sources=&quot;tabs&quot;, head=true)#
&lt;/body&gt;</code></pre>
