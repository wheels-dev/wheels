---
title: styleSheetLinkTag()
description: "Generates one or more &lt;link&gt; tags for including CSS stylesheets in your application. By default, it looks in the <code>publicstylesheets</code> folder of"
sidebar:
  label: styleSheetLinkTag()
  order: 0
---

## Signature

`styleSheetLinkTag()` — returns `string`

**Available in:** `controller`
**Category:** Asset Functions

## Description

Generates one or more &lt;link&gt; tags for including CSS stylesheets in your application. By default, it looks in the <code>publicstylesheets</code> folder of your app but can also handle external URLs or place stylesheets directly in the &lt;head&gt; section when needed.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `sources` | `string` | no | — | The name of one or many CSS files in the stylesheets folder, minus the `.css` extension. Pass a full URL to generate a tag for an external style sheet. Can also be called with the `source` argument. |
| `type` | `string` | no | `text/css` | The `type` attribute for the `link` tag. |
| `media` | `string` | no | `all` | The `media` attribute for the `link` tag. |
| `rel` | `string` | no | — | The `rel` attribute for the relation between the tag and href. |
| `head` | `boolean` | no | `false` | Set to `true` to place the output in the `head` area of the HTML page instead of the default behavior (which is to place the output where the function is called from). |
| `delim` | `string` | no | `,` | The delimiter to use for the list of CSS files. |
| `encode` | `boolean` | no | `true` | Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead. |

## Examples

<pre><code class='javascript'>&lt;!--- view code ---&gt;
&lt;head&gt;
    &lt;!--- Includes `public/stylesheets/styles.css` ---&gt;
    #styleSheetLinkTag(&quot;styles&quot;)#
    &lt;!--- Includes `public/stylesheets/blog.css` and `public/stylesheets/comments.css` ---&gt;
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
