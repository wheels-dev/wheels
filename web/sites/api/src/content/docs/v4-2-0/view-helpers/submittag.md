---
title: submitTag()
description: "Builds and returns a string containing a submit button form control."
sidebar:
  label: submitTag()
  order: 0
---

## Signature

`submitTag()` — returns `string`

**Available in:** `controller`
**Category:** General Form Functions

## Description

Builds and returns a string containing a submit button form control.
Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `value` | `string` | no | `Save changes` | Message to display in the button form control. |
| `image` | `string` | no | — | File name of the image file to use in the button form control. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>// 1. Basic submit button inside a form
#startFormTag(action=&quot;save&quot;)#
    &lt;!--- form controls go here ---&gt;
    #submitTag()#
#endFormTag()#
// -&gt; &lt;form action=&quot;/products/save&quot; method=&quot;post&quot;&gt;...&lt;input type=&quot;submit&quot; value=&quot;Save changes&quot;&gt;&lt;/form&gt;

// 2. Custom button label
#submitTag(value=&quot;Create Account&quot;)#
// -&gt; &lt;input type=&quot;submit&quot; value=&quot;Create Account&quot;&gt;

// 3. Image submit button
#submitTag(image=&quot;submit-button.png&quot;)#
// -&gt; &lt;input type=&quot;image&quot; src=&quot;/images/submit-button.png&quot;&gt;

// 4. Submit button with extra HTML attributes (class and id)
#submitTag(value=&quot;Place Order&quot;, class=&quot;btn btn-primary&quot;, id=&quot;order-submit&quot;)#
// -&gt; &lt;input type=&quot;submit&quot; value=&quot;Place Order&quot; class=&quot;btn btn-primary&quot; id=&quot;order-submit&quot;&gt;

// 5. Submit button wrapped with HTML using prepend and append
#submitTag(value=&quot;Save&quot;, prepend=&quot;&lt;div class=&quot;&quot;actions&quot;&quot;&gt;&quot;, append=&quot;&lt;/div&gt;&quot;)#
// -&gt; &lt;div class=&quot;actions&quot;&gt;&lt;input type=&quot;submit&quot; value=&quot;Save&quot;&gt;&lt;/div&gt;
</code></pre>
