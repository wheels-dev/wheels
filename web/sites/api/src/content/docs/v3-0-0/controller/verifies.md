---
title: verifies()
description: "Instructs a Wheels controller to check that certain criteria are met before executing an action. This is useful for enforcing request types, required parameters"
sidebar:
  label: verifies()
  order: 0
---

## Signature

`verifies()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Instructs a Wheels controller to check that certain criteria are met before executing an action. This is useful for enforcing request types, required parameters, session/cookie values, or custom verifications. Note that all undeclared arguments will be passed to <code>redirectTo()</code> call if a <code>handler</code> is not specified.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `only` | `string` | no | — | List of action names to limit this verification to. |
| `except` | `string` | no | — | List of action names to exclude this verification from. |
| `post` | `any` | no | — | Set to true to verify that this is a `POST` request. |
| `get` | `any` | no | — | Set to true to verify that this is a `GET` request. |
| `ajax` | `any` | no | — | Set to true to verify that this is an `AJAX` request. |
| `cookie` | `string` | no | — | Verify that the passed in variable name exists in the cookie scope. |
| `session` | `string` | no | — | Verify that the passed in variable name exists in the session scope. |
| `params` | `string` | no | — | Verify that the passed in variable name exists in the params struct. |
| `handler` | `string` | no | — | Pass in the name of a function that should handle failed verifications. The default is to just abort the request when a verification fails. |
| `cookieTypes` | `string` | no | — | List of types to check each listed cookie value against (will be passed through to your CFML engine's `IsValid` function). |
| `sessionTypes` | `string` | no | — | List of types to check each list session value against (will be passed through to your CFML engine's `IsValid` function). |
| `paramsTypes` | `string` | no | — | List of types to check each params value against (will be passed through to your CFML engine's `IsValid` function). |

## Examples

<pre><code class='javascript'>1. Tell Wheels to verify that the `handleForm` action is always a `POST` request when executed.
verifies(only=&quot;handleForm&quot;, post=true);

2. Make sure that the edit action is a `GET` request, that `userId` exists in the `params` struct, and that it's an integer.
verifies(only=&quot;edit&quot;, get=true, params=&quot;userId&quot;, paramsTypes=&quot;integer&quot;);

3. Just like above, only this time we want to invoke a custom function in our controller to handle the request when it is invalid.
verifies(only=&quot;edit&quot;, get=true, params=&quot;userId&quot;, paramsTypes=&quot;integer&quot;, handler=&quot;myCustomFunction&quot;);

4. Just like above, only this time instead of specifying a handler, we want to `redirect` the visitor to the index action of the controller and show an error in The Flash when the request is invalid.
verifies(only=&quot;edit&quot;, get=true, params=&quot;userId&quot;, paramsTypes=&quot;integer&quot;, action=&quot;index&quot;, error=&quot;Invalid userId&quot;);
</code></pre>
