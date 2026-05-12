---
title: endFormTag()
description: "Builds and returns a string containing the closing <code>form</code> tag. It’s typically used in conjunction with startFormTag()."
sidebar:
  label: endFormTag()
  order: 0
---

## Signature

`endFormTag()` — returns `string`

**Available in:** `controller`
**Category:** General Form Functions

## Description

Builds and returns a string containing the closing <code>form</code> tag. It’s typically used in conjunction with startFormTag().



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>#startFormTag(action=&quot;create&quot;)#
 &lt;input type=&quot;text&quot; name=&quot;firstName&quot; placeholder=&quot;First Name&quot;&gt;
 &lt;input type=&quot;text&quot; name=&quot;lastName&quot; placeholder=&quot;Last Name&quot;&gt;
#endFormTag()#

Output:
&lt;form action=&quot;/create&quot; method=&quot;post&quot;&gt;
 &lt;input type=&quot;text&quot; name=&quot;firstName&quot; placeholder=&quot;First Name&quot;&gt;
 &lt;input type=&quot;text&quot; name=&quot;lastName&quot; placeholder=&quot;Last Name&quot;&gt;
&lt;/form&gt;

#startFormTag(action=&quot;update&quot;)#
 &lt;input type=&quot;email&quot; name=&quot;email&quot; placeholder=&quot;Email&quot;&gt;
#endFormTag(prepend=&quot;&lt;div class='form-wrapper'&gt;&quot;, append=&quot;&lt;/div&gt;&quot;)#

Output:
&lt;div class='form-wrapper'&gt;
&lt;form action=&quot;/update&quot; method=&quot;post&quot;&gt;
 &lt;input type=&quot;email&quot; name=&quot;email&quot; placeholder=&quot;Email&quot;&gt;
&lt;/form&gt;
&lt;/div&gt;

#startFormTag(action=&quot;login&quot;)#
 &lt;input type=&quot;text&quot; name=&quot;username&quot;&gt;
#endFormTag(encode=true)#

Output:
&lt;form action=&quot;/login&quot; method=&quot;post&quot;&gt;
 &lt;input type=&quot;text&quot; name=&quot;username&quot;&gt;
&lt;/form&gt;

#startFormTag(action=&quot;register&quot;, prepend=&quot;&lt;section&gt;&quot;)#
 &lt;input type=&quot;text&quot; name=&quot;username&quot;&gt;
 &lt;input type=&quot;password&quot; name=&quot;password&quot;&gt;
#endFormTag(append=&quot;&lt;/section&gt;&quot;)#

Output:
&lt;section&gt;
&lt;form action=&quot;/register&quot; method=&quot;post&quot;&gt;
 &lt;input type=&quot;text&quot; name=&quot;username&quot;&gt;
 &lt;input type=&quot;password&quot; name=&quot;password&quot;&gt;
&lt;/form&gt;
&lt;/section&gt;
</code></pre>
