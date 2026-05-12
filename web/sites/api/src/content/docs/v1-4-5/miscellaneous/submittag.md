---
title: submitTag()
description: "Builds and returns a string containing a submit button form control. Note: Pass any additional arguments like class, rel, and id, and the generated tag will als"
sidebar:
  label: submitTag()
  order: 0
---

## Signature

`submitTag()` — returns `any`




## Description

Builds and returns a string containing a submit button form control. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `value` | `string` | yes | `Save changes` | Message to display in the button form control. |
| `image` | `string` | yes | — | File name of the image file to use in the button form control. |
| `disable` | `any` | yes | — | Whether or not to disable the button upon clicking. (prevents double-clicking.) |
| `prepend` | `string` | yes | — | See documentation for textField |
| `append` | `string` | yes | — | See documentation for textField |

</div>

## Examples

<pre>&lt;cfoutput&gt;
    #startFormTag(action=&quot;something&quot;)#
        &lt;!--- form controls go here ---&gt;
        #submitTag()#
    #endFormTag()#
&lt;/cfoutput&gt;</pre>
