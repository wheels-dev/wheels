---
title: includeContent()
description: "Outputs the content for a specific section in a layout. Works together with contentFor() to define and then inject content into layouts. Typically used for head"
sidebar:
  label: includeContent()
  order: 0
---

## Signature

`includeContent()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Outputs the content for a specific section in a layout. Works together with contentFor() to define and then inject content into layouts. Typically used for head, sidebar, footer, or other pluggable layout sections. If the requested section hasn’t been defined, it will either return nothing or the provided defaultValue.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | `body` | Name of layout section to return content for. |
| `defaultValue` | `string` | no | — | What to display as a default if the section is not defined. |

## Examples

<pre><code class='javascript'>1. In your view template, let's say `app/views/blog/post.cfm
contentFor(head='&lt;meta name=&quot;robots&quot; content=&quot;noindex,nofollow&quot;&gt;');
contentFor(head='&lt;meta name=&quot;author&quot; content=&quot;wheelsdude@wheelsify.com&quot;&gt;');

// In `app/views/layout.cfm`
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
