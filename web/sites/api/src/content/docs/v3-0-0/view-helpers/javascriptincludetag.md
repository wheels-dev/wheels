---
title: javaScriptIncludeTag()
description: "Generates &lt;script&gt; tags for including JavaScript files. Can handle local files in the javascripts folder or external URLs. Supports multiple files and opt"
sidebar:
  label: javaScriptIncludeTag()
  order: 0
---

## Signature

`javaScriptIncludeTag()` — returns `string`

**Available in:** `controller`
**Category:** Asset Functions

## Description

Generates &lt;script&gt; tags for including JavaScript files. Can handle local files in the javascripts folder or external URLs. Supports multiple files and optional placement in the HTML &lt;head&gt;.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `sources` | `string` | no | — | The name of one or many JavaScript files in the `javascripts` folder, minus the `.js` extension. Pass a full URL to access an external JavaScript file. Can also be called with the `source` argument. |
| `type` | `string` | no | `text/javascript` | The `type` attribute for the `script` tag. |
| `head` | `boolean` | no | `false` | Set to `true` to place the output in the `head` area of the HTML page instead of the default behavior (which is to place the output where the function is called from). |
| `delim` | `string` | no | `,` | The delimiter to use for the list of JavaScript files. |
| `encode` | `boolean` | no | `true` | Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead. |

</div>

## Examples

<pre><code class='javascript'>&lt;!--- View Code ---&gt;
&lt;head&gt;
    &lt;!--- Includes `public/javascripts/main.js` ---&gt;
    #javaScriptIncludeTag(&quot;main&quot;)#

    &lt;!--- Includes `publicjavascripts/blog.js` and `public/javascripts/accordion.js` ---&gt;
    #javaScriptIncludeTag(&quot;blog,accordion&quot;)#
    
    &lt;!--- Includes external JavaScript file ---&gt;
    #javaScriptIncludeTag(&quot;https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js&quot;)#
&lt;/head&gt;

&lt;body&gt;
    &lt;!--- Will still appear in the `head` ---&gt;
    #javaScriptIncludeTag(source=&quot;tabs&quot;, head=true, type="text/javascript")#
&lt;/body&gt;

</code></pre>
