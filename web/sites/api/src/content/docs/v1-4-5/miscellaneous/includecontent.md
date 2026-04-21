---
title: includeContent()
description: "Used to output the content for a particular section in a layout."
sidebar:
  label: includeContent()
  order: 0
---

## Signature

`includeContent()` — returns `any`




## Description

Used to output the content for a particular section in a layout.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | `body` | Name of layout section to return content for. |
| `defaultValue` | `string` | yes | — | What to display as a default if the section is not defined. |

</div>

## Examples

<pre>&lt;!--- In your view template, let''s say `views/blog/post.cfm ---&gt;
&lt;cfset contentFor(head=''&lt;meta name=&quot;robots&quot; content=&quot;noindex,nofollow&quot;&gt;&quot;'')&gt;
&lt;cfset contentFor(head=''&lt;meta name=&quot;author&quot; content=&quot;wheelsdude@wheelsify.com&quot;'')&gt;

&lt;!--- In `views/layout.cfm` ---&gt;
&lt;html&gt;
	&lt;head&gt;
	    &lt;title&gt;My Site&lt;/title&gt;
	    ##includeContent(&quot;head&quot;)##
	&lt;/head&gt;
	&lt;body&gt;
		&lt;cfoutput&gt;
			##includeContent()##
		&lt;/cfoutput&gt;
	&lt;/body&gt;
&lt;/html&gt;</pre>
