---
title: flashMessages()
description: "Displays a marked-up listing of messages that exist in the Flash."
sidebar:
  label: flashMessages()
  order: 0
---

## Signature

`flashMessages()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Displays a marked-up listing of messages that exist in the Flash.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `keys` | `string` | no | — | The key (or list of keys) to show the value for. You can also use the `key` argument instead for better readability when accessing a single key. |
| `class` | `string` | no | `flash-messages` | HTML `class` to set on the `div` element that contains the messages. |
| `includeEmptyContainer` | `boolean` | no | `false` | Includes the `div` container even if the Flash is empty. |
| `encode` | `boolean` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>// In the controller action
flashInsert(success=&quot;Your post was successfully submitted.&quot;);
flashInsert(alert=&quot;Don't forget to tweet about this post!&quot;);
flashInsert(error=&quot;This is an error message.&quot;);

&lt;!--- In the layout or view ---&gt;
#flashMessages()#

&lt;!--- Generates this (sorted alphabetically):---&gt;
&lt;div class=&quot;flashMessages&quot;&gt;
	&lt;p class=&quot;alertMessage&quot;&gt;
		Don't forget to tweet about this post!
	&lt;/p&gt;
	&lt;p class=&quot;errorMessage&quot;&gt;
		This is an error message.
	&lt;/p&gt;
	&lt;p class=&quot;successMessage&quot;&gt;
		Your post was successfully submitted.
	&lt;/p&gt;
&lt;/div&gt;


&lt;!---  Only show the &quot;success&quot; key in the view ---&gt;
#flashMessages(key=&quot;success&quot;)#

&lt;!--- Generates this: ---&gt;
&lt;div class=&quot;flashMessage&quot;&gt;
	&lt;p class=&quot;successMessage&quot;&gt;
		Your post was successfully submitted.
	&lt;/p&gt;
&lt;/div&gt;


&lt;!--- Show only the &quot;success&quot; and &quot;alert&quot; keys in the view, in that order ---&gt;
#flashMessages(keys=&quot;success,alert&quot;)#

&lt;!--- Generates this (sorted alphabetically):---&gt;
&lt;div class=&quot;flashMessages&quot;&gt;
	&lt;p class=&quot;successMessage&quot;&gt;
		Your post was successfully submitted.
	&lt;/p&gt;
	&lt;p class=&quot;alertMessage&quot;&gt;
		Don't forget to tweet about this post!
	&lt;/p&gt;
&lt;/div&gt;</code></pre>
