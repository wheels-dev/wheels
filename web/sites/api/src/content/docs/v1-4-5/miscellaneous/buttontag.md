---
title: buttonTag()
description: "Builds and returns a string containing a button form control."
sidebar:
  label: buttonTag()
  order: 0
---

## Signature

`buttonTag()` — returns `any`




## Description

Builds and returns a string containing a button form control.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `content` | `string` | yes | `Save changes` | Content to display inside the button. |
| `type` | `string` | yes | `submit` | The type for the button: button, reset, or submit. |
| `value` | `string` | yes | `save` | The value of the button when submitted. |
| `image` | `string` | yes | — | File name of the image file to use in the button form control. |
| `disable` | `any` | yes | — | Whether or not to disable the button upon clicking (prevents double-clicking). |
| `prepend` | `string` | yes | — | See documentation for textField |
| `append` | `string` | yes | — | See documentation for textField |

## Examples

<pre>&lt;!--- view code ---&gt;
&lt;cfoutput&gt;
    #startFormTag(action=&quot;something&quot;)#
        &lt;!--- form controls go here ---&gt;
        #buttonTag(content=&quot;Submit this form&quot;, value=&quot;save&quot;)#
    #endFormTag()#
&lt;/cfoutput&gt;</pre>
