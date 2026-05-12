---
title: renderPartial()
description: "Instructs the controller to render a partial when it's finished processing the action."
sidebar:
  label: renderPartial()
  order: 0
---

## Signature

`renderPartial()` — returns `any`




## Description

Instructs the controller to render a partial when it's finished processing the action.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `partial` | `string` | yes | — | The name of the partial file to be used. Prefix with a leading slash / if you need to build a path from the root views folder. Do not include the partial filename's underscore and file extension. |
| `cache` | `any` | yes | — | See documentation for renderPage. |
| `layout` | `string` | yes | — | See documentation for renderPage. |
| `returnAs` | `string` | yes | — | See documentation for renderPage. |
| `dataFunction` | `any` | yes | `true` | Name of a controller function to load data from. |

</div>

## Examples

<pre>// Render the partial `_comment.cfm` located in the current controller''s view folder
renderPartial(&quot;comment&quot;);

// Render the partial at `views/shared/_comment.cfm`
renderPartial(&quot;/shared/comment&quot;);</pre>
