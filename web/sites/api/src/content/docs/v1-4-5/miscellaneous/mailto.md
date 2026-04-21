---
title: mailTo()
description: "Creates a mailto link tag to the specified email address, which is also used as the name of the link unless name is specified."
sidebar:
  label: mailTo()
  order: 0
---

## Signature

`mailTo()` — returns `any`




## Description

Creates a mailto link tag to the specified email address, which is also used as the name of the link unless name is specified.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `emailAddress` | `string` | yes | — | The email address to link to. |
| `name` | `string` | yes | — | A string to use as the link text ("Joe" or "Support Department", for example). |
| `encode` | `boolean` | yes | `false` | Pass true here to encode the email address, making it harder for bots to harvest it for example. |

</div>

## Examples

<pre>#mailTo(emailAddress=&quot;webmaster@yourdomain.com&quot;, name=&quot;Contact our Webmaster&quot;)#
-&gt; &lt;a href=&quot;mailto:webmaster@yourdomain.com&quot;&gt;Contact our Webmaster&lt;/a&gt;</pre>
