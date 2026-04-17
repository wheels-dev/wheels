---
title: includeContent()
description: "Used to output the content for a particular section in a layout."
sidebar:
  label: includeContent()
  order: 0
---

## Signature

`includeContent()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Used to output the content for a particular section in a layout.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | `body` | Name of layout section to return content for. |
| `defaultValue` | `string` | no | — | What to display as a default if the section is not defined. |

## Examples

<pre><code class='javascript'>&lt;!--- In your view template, let's say `views/blog/post.cfm---&gt;
contentFor(head='&lt;meta name=&quot;robots&quot; content=&quot;noindex,nofollow&quot;&gt;');
contentFor(head='&lt;meta name=&quot;author&quot; content=&quot;wheelsdude@wheelsify.com&quot;&gt;');

// In `views/layout.cfm`
&lt;html&gt;
	&lt;head&gt;
	    &lt;title&gt;My Site&lt;/title&gt;
	    #includeContent(&quot;head&quot;)#
	&lt;/head&gt;
	&lt;body&gt;
		&lt;cfoutput&gt;
			#includeContent()#
		&lt;/cfoutput&gt;
	&lt;/body&gt;
&lt;/html&gt;</code></pre>
