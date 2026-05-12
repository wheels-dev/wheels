---
title: buttonTo()
description: "Creates a form containing a single button that submits to a URL. The URL is constructed the same way as linkTo(). This helper is useful when you want a button t"
sidebar:
  label: buttonTo()
  order: 0
---

## Signature

`buttonTo()` — returns `string`

**Available in:** `controller`
**Category:** Link Functions

## Description

Creates a form containing a single button that submits to a URL. The URL is constructed the same way as linkTo(). This helper is useful when you want a button that performs a specific action (GET, POST, PUT, DELETE, PATCH) without manually creating a form.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | no | — | The text content of the button. |
| `image` | `string` | no | — | If you want to use an image for the button pass in the link to it here (relative from the `images` folder). |
| `route` | `string` | no | — | Name of a route that you have configured in `config/routes.cfm`. |
| `controller` | `string` | no | — | Name of the controller to include in the URL. |
| `action` | `string` | no | — | Name of the action to include in the URL. |
| `key` | `any` | no | — | Key(s) to include in the URL. |
| `params` | `string` | no | — | Any additional parameters to be set in the query string (example: `wheels=cool&x=y`). Please note that Wheels uses the `&` and `=` characters to split the parameters and encode them properly for you. However, if you need to pass in `&` or `=` as part of the value, then you need to encode them (and only them), example: `a=cats%26dogs%3Dtrouble!&b=1`. |
| `anchor` | `string` | no | — | Sets an anchor name to be appended to the path. |
| `method` | `string` | no | — | The type of `method` to use in the `form` tag (`delete`, `get`, `patch`, `post`, and `put` are the options). |
| `onlyPath` | `boolean` | no | `true` | If `true`, returns only the relative URL (no protocol, host name or port). |
| `host` | `string` | no | — | Set this to override the current host. |
| `protocol` | `string` | no | — | Set this to override the current protocol. |
| `port` | `numeric` | no | `0` | Set this to override the current port number. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>1. Basic button submitting to an action
#buttonTo(text="Delete Account", action="performDelete", disable="Wait...")#

2. Button with an ID and class applied to the input
#buttonTo(text="Edit", action="edit", inputId="edit-button", inputClass="edit-button-class")#

3. Button using an image instead of text
#buttonTo(image="delete-icon.png", action="delete")#

4. Button linking to a specific route with query parameters
#buttonTo(text="View Report", route="reportRoute", params="year=2025&month=9")#

5. Button using DELETE method
#buttonTo(text="Remove", action="deleteItem", method="delete")#</code></pre>
