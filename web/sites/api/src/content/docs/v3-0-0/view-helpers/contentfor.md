---
title: contentFor()
description: "contentFor() is used to store a section's output in a layout. It allows you to define content in your view templates and then render it in a layout using #inclu"
sidebar:
  label: contentFor()
  order: 0
---

## Signature

`contentFor()` — returns `void`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

contentFor() is used to store a section's output in a layout. It allows you to define content in your view templates and then render it in a layout using #includeContent()#. The function maintains a stack for each section, so multiple pieces of content can be added in a controlled order.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `position` | `any` | no | `last` | The position in the section's stack where you want the content placed. Valid values are `first`, `last`, or the numeric position. |
| `overwrite` | `any` | no | `false` | Whether or not to overwrite any of the content. Valid values are `false`, `true`, or `all`. |

</div>

## Examples

<pre><code class='javascript'>1. Basic usage
&lt;!--- In your view ---&gt;
&lt;cfsavecontent variable="mySidebar"&gt;
    &lt;h1&gt;My Sidebar Text&lt;/h1&gt;
&lt;/cfsavecontent&gt;

&lt;cfset contentFor(sidebar=mySidebar)&gt;

&lt;!--- In your layout ---&gt;
&lt;html&gt;
    &lt;head&gt;&lt;title&gt;My Site&lt;/title&gt;&lt;/head&gt;
    &lt;body&gt;
        &lt;cfoutput&gt;
            #includeContent("sidebar")#  &lt;!-- Renders the sidebar content --&gt;
            #includeContent()#           &lt;!-- Renders main content --&gt;
        &lt;/cfoutput&gt;
    &lt;/body&gt;
&lt;/html&gt;

2. Adding multiple pieces to the same section
&lt;cfset contentFor(sidebar="First piece of content")&gt;
&lt;cfset contentFor(sidebar="Second piece of content", position="first")&gt;

&lt;!--- Renders 'Second piece of content' first, then 'First piece of content' --&gt;
#includeContent("sidebar")#

3. Overwriting content
&lt;cfset contentFor(sidebar="Old content")&gt;
&lt;cfset contentFor(sidebar="New content", overwrite=true)&gt;

&lt;!--- Only 'New content' will be rendered --&gt;
#includeContent("sidebar")#</code></pre>
