---
title: contentFor()
description: "Used to store a section's output for rendering within a layout."
sidebar:
  label: contentFor()
  order: 0
---

## Signature

`contentFor()` — returns `void`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Used to store a section's output for rendering within a layout.
This content store acts as a stack, so you can store multiple pieces of content for a given section.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `position` | `any` | no | `last` | The position in the section's stack where you want the content placed. Valid values are `first`, `last`, or the numeric position. |
| `overwrite` | `any` | no | `false` | Whether or not to overwrite any of the content. Valid values are `false`, `true`, or `all`. |

## Examples

<pre><code class='javascript'>&lt;!--- In your view ---&gt;
&lt;cfsavecontent variable=&quot;mySidebar&quot;&gt;
&lt;h1&gt;My Sidebar Text&lt;/h1&gt;
&lt;/cfsavecontent&gt;
&lt;cfset contentFor(sidebar=mySidebar)&gt;

&lt;!--- In your layout ---&gt;
&lt;html&gt;
	&lt;head&gt;
	    &lt;title&gt;My Site&lt;/title&gt;
	&lt;/head&gt;
	&lt;body&gt;
		&lt;cfoutput&gt;
			#includeContent(&quot;sidebar&quot;)#
			#includeContent()#
		&lt;/cfoutput&gt;
	&lt;/body&gt;
&lt;/html&gt;</code></pre>
