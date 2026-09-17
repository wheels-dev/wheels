---
title: buttonTag()
description: "Builds and returns a string containing a button form control."
sidebar:
  label: buttonTag()
  order: 0
---

## Signature

`buttonTag()` — returns `string`

**Available in:** `controller`
**Category:** General Form Functions

## Description

Builds and returns a string containing a button form control.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `content` | `string` | no | `Save changes` | Content to display inside the button. |
| `type` | `string` | no | `submit` | The type for the button: `button`, `reset`, or `submit`. |
| `value` | `string` | no | `save` | The value of the button when submitted. |
| `image` | `string` | no | — | File name of the image file to use in the button form control. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>// 1. Basic submit button inside a form
#startFormTag(action=&quot;create&quot;)#
    #buttonTag(content=&quot;Save changes&quot;, value=&quot;save&quot;)#
#endFormTag()#
&lt;!--- Produces: &lt;button type=&quot;submit&quot; value=&quot;save&quot;&gt;Save changes&lt;/button&gt; ---&gt;

// 2. Reset button to clear form fields
#buttonTag(content=&quot;Clear form&quot;, type=&quot;reset&quot;)#
&lt;!--- Produces: &lt;button type=&quot;reset&quot; value=&quot;save&quot;&gt;Clear form&lt;/button&gt; ---&gt;

// 3. Plain button (no form submission) with a CSS class and id
#buttonTag(content=&quot;Open dialog&quot;, type=&quot;button&quot;, value=&quot;open&quot;, class=&quot;btn btn-secondary&quot;, id=&quot;openDialogBtn&quot;)#
&lt;!--- Produces: &lt;button type=&quot;button&quot; value=&quot;open&quot; class=&quot;btn btn-secondary&quot; id=&quot;openDialogBtn&quot;&gt;Open dialog&lt;/button&gt; ---&gt;

// 4. Submit button wrapped in a paragraph using prepend and append
#buttonTag(content=&quot;Submit&quot;, value=&quot;submit&quot;, prepend=&quot;&lt;p&gt;&quot;, append=&quot;&lt;/p&gt;&quot;)#
&lt;!--- Produces: &lt;p&gt;&lt;button type=&quot;submit&quot; value=&quot;submit&quot;&gt;Submit&lt;/button&gt;&lt;/p&gt; ---&gt;

// 5. Image button (renders an img tag inside the button element)
#buttonTag(content=&quot;&quot;, image=&quot;submit-icon.png&quot;, value=&quot;save&quot;)#
&lt;!--- Produces: &lt;button type=&quot;submit&quot; value=&quot;save&quot;&gt;&lt;img src=&quot;/images/submit-icon.png&quot; alt=&quot;Submit Icon&quot; /&gt;&lt;/button&gt; ---&gt;
</code></pre>
