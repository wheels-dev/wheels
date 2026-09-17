---
title: mailTo()
description: "Creates a <code>mailto</code> link tag to the specified email address, which is also used as the name of the link unless name is specified."
sidebar:
  label: mailTo()
  order: 0
---

## Signature

`mailTo()` — returns `string`

**Available in:** `controller`
**Category:** Link Functions

## Description

Creates a <code>mailto</code> link tag to the specified email address, which is also used as the name of the link unless name is specified.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `emailAddress` | `string` | yes | — | The email address to link to. |
| `name` | `string` | no | — | A string to use as the link text ("Joe" or "Support Department", for example). |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>// 1. Basic mailto link using the email address as the link text
mailTo(emailAddress=&quot;webmaster@example.com&quot;);
// -&gt; &lt;a href=&quot;mailto:webmaster@example.com&quot;&gt;webmaster@example.com&lt;/a&gt;

// 2. Mailto link with a custom display name
mailTo(emailAddress=&quot;support@example.com&quot;, name=&quot;Contact Support&quot;);
// -&gt; &lt;a href=&quot;mailto:support@example.com&quot;&gt;Contact Support&lt;/a&gt;

// 3. Mailto link with additional HTML attributes (class, title)
mailTo(emailAddress=&quot;info@example.com&quot;, name=&quot;Email Us&quot;, class=&quot;email-link&quot;, title=&quot;Send us a message&quot;);
// -&gt; &lt;a href=&quot;mailto:info@example.com&quot; class=&quot;email-link&quot; title=&quot;Send us a message&quot;&gt;Email Us&lt;/a&gt;
</code></pre>
