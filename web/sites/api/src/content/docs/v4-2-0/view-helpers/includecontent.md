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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | `body` | Name of layout section to return content for. |
| `defaultValue` | `string` | no | — | What to display as a default if the section is not defined. |
| `encode` | `any` | no | — | Opt-in HTML encode of the stored section. Default is omitted (no encode) so layouts that store HTML keep working. |

</div>

## Examples

<pre><code class='javascript'>// 1. Output the main page body inside a layout (default section is &quot;body&quot;)
// In `app/views/layout.cfm`:
&lt;html&gt;
	&lt;head&gt;
		&lt;title&gt;My Site&lt;/title&gt;
	&lt;/head&gt;
	&lt;body&gt;
		&lt;cfoutput&gt;
			#includeContent()#
		&lt;/cfoutput&gt;
	&lt;/body&gt;
&lt;/html&gt;

// 2. Define a named section in a view, then render it in the layout
// In `app/views/blog/show.cfm`:
contentFor(head='&lt;meta name=&quot;description&quot; content=&quot;Read our latest post&quot;&gt;');

// In `app/views/layout.cfm`:
&lt;html&gt;
	&lt;head&gt;
		&lt;title&gt;My Site&lt;/title&gt;
		&lt;cfoutput&gt;#includeContent(&quot;head&quot;)#&lt;/cfoutput&gt;
	&lt;/head&gt;
	&lt;body&gt;
		&lt;cfoutput&gt;#includeContent()#&lt;/cfoutput&gt;
	&lt;/body&gt;
&lt;/html&gt;

// 3. Provide a default value when a section may not have been defined
&lt;cfoutput&gt;
	#includeContent(name=&quot;sidebar&quot;, defaultValue=&quot;&lt;p&gt;No sidebar content.&lt;/p&gt;&quot;)#
&lt;/cfoutput&gt;
</code></pre>
