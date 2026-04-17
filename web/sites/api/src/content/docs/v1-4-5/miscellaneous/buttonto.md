---
title: buttonTo()
description: "Creates a form containing a single button that submits to the URL. The URL is built the same way as the linkTo function."
sidebar:
  label: buttonTo()
  order: 0
---

## Signature

`buttonTo()` — returns `any`




## Description

Creates a form containing a single button that submits to the URL. The URL is built the same way as the linkTo function.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text content of the button. |
| `confirm` | `string` | yes | — | See documentation for linkTo. |
| `image` | `string` | yes | — | If you want to use an image for the button pass in the link to it here (relative from the images folder). |
| `disable` | `any` | yes | — | Pass in true if you want the button to be disabled when clicked (can help prevent multiple clicks), or pass in a string if you want the button disabled and the text on the button updated (to "please wait...", for example). |
| `route` | `string` | yes | — | See documentation for URLFor. |
| `controller` | `string` | yes | — | See documentation for URLFor. |
| `action` | `string` | yes | — | See documentation for URLFor. |
| `key` | `any` | yes | — | See documentation for URLFor. |
| `params` | `string` | yes | — | See documentation for URLFor. |
| `anchor` | `string` | yes | — | See documentation for URLFor. |
| `onlyPath` | `boolean` | yes | `true` | See documentation for URLFor. |
| `host` | `string` | yes | — | See documentation for URLFor. |
| `protocol` | `string` | yes | — | See documentation for URLFor. |
| `port` | `numeric` | yes | `0` | See documentation for URLFor. |

## Examples

<pre>#buttonTo(text=&quot;Delete Account&quot;, action=&quot;perFormDelete&quot;, disable=&quot;Wait...&quot;)#

// apply attributes to the input element by prefixing any arguments with &quot;input&quot;
#buttonTo(text=&quot;Edit&quot;, action=&quot;edit&quot;, inputId=&quot;edit-button&quot;, inputClass=&quot;edit-button-class&quot;)#</pre>
