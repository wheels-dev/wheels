---
title: flashMessages()
description: "Displays a marked-up listing of messages that exist in the Flash."
sidebar:
  label: flashMessages()
  order: 0
---

## Signature

`flashMessages()` — returns `any`




## Description

Displays a marked-up listing of messages that exist in the Flash.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `keys` | `string` | yes | — | The key (or list of keys) to show the value for. You can also use the key argument instead for better readability when accessing a single key. |
| `class` | `string` | yes | `flashMessages` | HTML class to set on the div element that contains the messages. |
| `includeEmptyContainer` | `boolean` | yes | `false` | Includes the div container even if the Flash is empty. |
| `lowerCaseDynamicClassValues` | `boolean` | yes | `false` | Outputs all class attribute values in lower case (except the main one). |

</div>

## Examples

<pre>&lt;!--- In the controller action ---&gt;
flashInsert(success=&quot;Your post was successfully submitted.&quot;);
flashInsert(alert=&quot;Don''t forget to tweet about this post!&quot;);
flashInsert(error=&quot;This is an error message.&quot;);

&lt;!--- In the layout or view ---&gt;
&lt;cfoutput&gt;
	#flashMessages()#
&lt;/cfoutput&gt;
&lt;!---
	Generates this (sorted alphabetically):
	&lt;div class=&quot;flashMessages&quot;&gt;
		&lt;p class=&quot;alertMessage&quot;&gt;
			Don''t forget to tweet about this post!
		&lt;/p&gt;
		&lt;p class=&quot;errorMessage&quot;&gt;
			This is an error message.
		&lt;/p&gt;
		&lt;p class=&quot;successMessage&quot;&gt;
			Your post was successfully submitted.
		&lt;/p&gt;
	&lt;/div&gt;
---&gt;

&lt;!--- Only show the &quot;success&quot; key in the view ---&gt;
&lt;cfoutput&gt;
	#flashMessages(key=&quot;success&quot;)#
&lt;/cfoutput&gt;
&lt;!---
	Generates this:
	&lt;div class=&quot;flashMessage&quot;&gt;
		&lt;p class=&quot;successMessage&quot;&gt;
			Your post was successfully submitted.
		&lt;/p&gt;
	&lt;/div&gt;
---&gt;

&lt;!--- Show only the &quot;success&quot; and &quot;alert&quot; keys in the view, in that order ---&gt;
&lt;cfoutput&gt;
	#flashMessages(keys=&quot;success,alert&quot;)#
&lt;/cfoutput&gt;
&lt;!---
	Generates this (sorted alphabetically):
	&lt;div class=&quot;flashMessages&quot;&gt;
		&lt;p class=&quot;successMessage&quot;&gt;
			Your post was successfully submitted.
		&lt;/p&gt;
		&lt;p class=&quot;alertMessage&quot;&gt;
			Don''t forget to tweet about this post!
		&lt;/p&gt;
	&lt;/div&gt;
---&gt;</pre>
