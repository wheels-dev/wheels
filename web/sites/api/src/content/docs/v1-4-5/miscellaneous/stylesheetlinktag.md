---
title: styleSheetLinkTag()
description: "Returns a link tag for a stylesheet (or several) based on the supplied arguments."
sidebar:
  label: styleSheetLinkTag()
  order: 0
---

## Signature

`styleSheetLinkTag()` — returns `any`




## Description

Returns a link tag for a stylesheet (or several) based on the supplied arguments.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `sources` | `string` | yes | — | The name of one or many CSS files in the stylesheets folder, minus the .css extension. (Can also be called with the source argument.) Pass a full URL to generate a tag for an external style sheet. |
| `type` | `string` | yes | `text/css` | The type attribute for the link tag. |
| `media` | `string` | yes | `all` | The media attribute for the link tag. |
| `head` | `string` | yes | `false` | Set to true to place the output in the head area of the HTML page instead of the default behavior, which is to place the output where the function is called from. |
| `delim` | `string` | yes | `,` | the delimiter to use for the list of stylesheets |

## Examples

<pre>styleSheetLinkTag([ sources, type, media, head, delim ]) &lt;!--- view code ---&gt;
&lt;head&gt;
    &lt;!--- Includes `stylesheets/styles.css` ---&gt;
    #styleSheetLinkTag(&quot;styles&quot;)#
    &lt;!--- Includes `stylesheets/blog.css` and `stylesheets/comments.css` ---&gt;
    #styleSheetLinkTag(&quot;blog,comments&quot;)#
    &lt;!--- Includes printer style sheet ---&gt;
    #styleSheetLinkTag(source=&quot;print&quot;, media=&quot;print&quot;)#
    &lt;!--- Includes external style sheet ---&gt;
    #styleSheetLinkTag(&quot;http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.0/themes/cupertino/jquery-ui.css&quot;)#
&lt;/head&gt;

&lt;body&gt;
    &lt;!--- This will still appear in the `head` ---&gt;
    #styleSheetLinkTag(source=&quot;tabs&quot;, head=true)#
&lt;/body&gt;</pre>
