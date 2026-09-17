---
title: buttonTo()
description: "Creates a form containing a single button that submits to the URL. Note: Pass any additional arguments by prefixing them with \"input\" like inputClass, inputRel,"
sidebar:
  label: buttonTo()
  order: 0
---

## Signature

`buttonTo()` — returns `string`

**Available in:** `controller`
**Category:** Link Functions

## Description

Creates a form containing a single button that submits to the URL. Note: Pass any additional arguments by prefixing them with "input" like inputClass, inputRel, and inputId, and the generated tag will also include those values as HTML attributes.
The URL is built the same way as the <code>linkTo</code> function.



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

<pre><code class='javascript'>// 1. Basic button that submits to a controller/action
#buttonTo(text=&quot;Delete Account&quot;, controller=&quot;account&quot;, action=&quot;delete&quot;)#
&lt;!--- Outputs: &lt;form action=&quot;/account/delete&quot; method=&quot;post&quot;&gt;&lt;button type=&quot;submit&quot;&gt;Delete Account&lt;/button&gt;&lt;/form&gt; ---&gt;

// 2. If you're already in the `account` controller, CFWheels will assume the current controller
#buttonTo(text=&quot;Delete Account&quot;, action=&quot;delete&quot;)#
&lt;!--- Outputs: &lt;form action=&quot;/account/delete&quot; method=&quot;post&quot;&gt;&lt;button type=&quot;submit&quot;&gt;Delete Account&lt;/button&gt;&lt;/form&gt; ---&gt;

// 3. Use `method` to send a DELETE request (a hidden `_method` field is added automatically)
#buttonTo(text=&quot;Remove Post&quot;, controller=&quot;blog&quot;, action=&quot;delete&quot;, key=99, method=&quot;delete&quot;)#
&lt;!--- Outputs: &lt;form action=&quot;/blog/delete/99&quot; method=&quot;post&quot;&gt;&lt;input type=&quot;hidden&quot; name=&quot;_method&quot; value=&quot;delete&quot; /&gt;&lt;button type=&quot;submit&quot;&gt;Remove Post&lt;/button&gt;&lt;/form&gt; ---&gt;

// 4. Use a named route configured in `config/routes.cfm`
#buttonTo(text=&quot;Archive&quot;, route=&quot;archivePost&quot;, postId=12)#

// 5. Show a &quot;please wait&quot; state by disabling the button on click — pass extra attributes to the button using the `input` prefix
#buttonTo(text=&quot;Place Order&quot;, action=&quot;checkout&quot;, inputId=&quot;checkout-btn&quot;, inputClass=&quot;btn btn-primary&quot;, inputData-disable-with=&quot;Processing...&quot;)#

// 6. Use an image instead of text for the button
#buttonTo(image=&quot;icons/trash.png&quot;, action=&quot;destroy&quot;, key=params.id, method=&quot;delete&quot;)#
</code></pre>
