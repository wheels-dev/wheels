---
title: javaScriptIncludeTag()
description: "Returns a <code>script</code> tag for a JavaScript file (or several) based on the supplied arguments."
sidebar:
  label: javaScriptIncludeTag()
  order: 0
---

## Signature

`javaScriptIncludeTag()` — returns `string`

**Available in:** `controller`
**Category:** Asset Functions

## Description

Returns a <code>script</code> tag for a JavaScript file (or several) based on the supplied arguments.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `sources` | `string` | no | — | The name of one or many JavaScript files in the `javascripts` folder, minus the `.js` extension. Pass a full URL to access an external JavaScript file. Can also be called with the `source` argument. |
| `type` | `string` | no | `text/javascript` | The `type` attribute for the `script` tag. |
| `head` | `boolean` | no | `false` | Set to `true` to place the output in the `head` area of the HTML page instead of the default behavior (which is to place the output where the function is called from). |
| `delim` | `string` | no | `,` | The delimiter to use for the list of JavaScript files. |
| `encode` | `boolean` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre><code class='javascript'>&lt;!--- View Code ---&gt;
&lt;head&gt;
    &lt;!--- Includes `javascripts/main.js` ---&gt;
    #javaScriptIncludeTag(&quot;main&quot;)#

    &lt;!--- Includes `javascripts/blog.js` and `javascripts/accordion.js` ---&gt;
    #javaScriptIncludeTag(&quot;blog,accordion&quot;)#
    
    &lt;!--- Includes external JavaScript file ---&gt;
    #javaScriptIncludeTag(&quot;https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js&quot;)#
&lt;/head&gt;

&lt;body&gt;
    &lt;!--- Will still appear in the `head` ---&gt;
    #javaScriptIncludeTag(source=&quot;tabs&quot;, head=true)#
&lt;/body&gt;

</code></pre>
