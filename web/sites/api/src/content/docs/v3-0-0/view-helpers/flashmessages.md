---
title: flashMessages()
description: "The flashMessages() function generates a formatted HTML output of messages stored in the Flash scope. It is typically used in views or layouts to display tempor"
sidebar:
  label: flashMessages()
  order: 0
---

## Signature

`flashMessages()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

The flashMessages() function generates a formatted HTML output of messages stored in the Flash scope. It is typically used in views or layouts to display temporary notifications like success messages, alerts, or errors. You can choose to display all messages, a specific key, or multiple keys in a defined order. Additional options let you customize the container’s HTML class, include an empty container if no messages exist, and control whether the message content is URL-encoded.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `keys` | `string` | no | — | The key (or list of keys) to show the value for. You can also use the `key` argument instead for better readability when accessing a single key. |
| `class` | `string` | no | `flash-messages` | HTML `class` to set on the `div` element that contains the messages. |
| `includeEmptyContainer` | `boolean` | no | `false` | Includes the `div` container even if the Flash is empty. |
| `encode` | `boolean` | no | `true` | Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead. |

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
