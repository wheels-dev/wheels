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
| `encode` | `any` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre>#mailTo(emailAddress=&quot;webmaster@yourdomain.com&quot;, name=&quot;Contact our Webmaster&quot;)#
&lt;!--- Outputs: &lt;a href=&quot;mailto:webmaster@yourdomain.com&quot;&gt;Contact our Webmaster&lt;/a&gt; ---&gt;</pre>
