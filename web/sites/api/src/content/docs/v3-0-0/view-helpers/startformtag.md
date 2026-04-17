---
title: startFormTag()
description: "Builds and returns an opening &lt;form&gt; tag. The form’s action URL is automatically generated following the same rules as <code>urlFor()</code>. You can pass"
sidebar:
  label: startFormTag()
  order: 0
---

## Signature

`startFormTag()` — returns `string`

**Available in:** `controller`
**Category:** General Form Functions

## Description

Builds and returns an opening &lt;form&gt; tag. The form’s action URL is automatically generated following the same rules as <code>urlFor()</code>. You can pass standard Wheels routing arguments (controller, action, route, key, params) as well as custom HTML attributes (id, class, rel, etc.). Use this in combination with <code>endFormTag()</code> to wrap your form controls.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `method` | `string` | no | `post` | The type of `method` to use in the `form` tag (`delete`, `get`, `patch`, `post`, and `put` are the options). |
| `multipart` | `boolean` | no | `false` | Set to `true` if the form should be able to upload files. |
| `route` | `string` | no | — | Name of a route that you have configured in `config/routes.cfm`. |
| `controller` | `string` | no | — | Name of the controller to include in the URL. |
| `action` | `string` | no | — | Name of the action to include in the URL. |
| `key` | `any` | no | — | Key(s) to include in the URL. |
| `params` | `string` | no | — | Any additional parameters to be set in the query string (example: wheels=cool&x=y). Please note that Wheels uses the & and = characters to split the parameters and encode them properly for you. However, if you need to pass in & or = as part of the value, then you need to encode them (and only them), example: a=cats%26dogs%3Dtrouble!&b=1. |
| `anchor` | `string` | no | — | Sets an anchor name to be appended to the path. |
| `onlyPath` | `boolean` | no | `true` | If true, returns only the relative URL (no protocol, host name or port). |
| `host` | `string` | no | — | Set this to override the current host. |
| `protocol` | `string` | no | — | Set this to override the current protocol. |
| `port` | `numeric` | no | `0` | Set this to override the current port number. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre><code class='javascript'>1. Basic form for create action
#startFormTag(action=&quot;create&quot;)#
    #textFieldTag(name=&quot;firstName&quot;)#
    #submitTag(value=&quot;Save&quot;)#
#endFormTag()#

2. Form with file upload
#startFormTag(action=&quot;upload&quot;, multipart=true)#
    #fileFieldTag(name=&quot;profilePicture&quot;)#
    #submitTag(value=&quot;Upload&quot;)#
#endFormTag()#

3. Using a named route
#startFormTag(route=&quot;registerUser&quot;)#
    #textFieldTag(name=&quot;email&quot;)#
    #passwordFieldTag(name=&quot;password&quot;)#
    #submitTag(value=&quot;Register&quot;)#
#endFormTag()#

4. Passing keys and params
#startFormTag(controller=&quot;posts&quot;, action=&quot;edit&quot;, key=42, params=&quot;draft=true&quot;)#
    #textAreaTag(name=&quot;content&quot;)#
    #submitTag(value=&quot;Update Post&quot;)#
#endFormTag()#

5. Custom attributes
#startFormTag(action=&quot;search&quot;, id=&quot;searchForm&quot;, class=&quot;inline-form&quot;)#
    #textFieldTag(name=&quot;q&quot;)#
    #submitTag(value=&quot;Search&quot;)#
#endFormTag()#</code></pre>
