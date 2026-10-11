---
title: verifies()
description: "Instructs Wheels to verify that some specific criteria are met before running an action."
sidebar:
  label: verifies()
  order: 0
---

## Signature

`verifies()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Instructs Wheels to verify that some specific criteria are met before running an action.
Note that all undeclared arguments will be passed to <code>redirectTo()</code> call if a <code>handler</code> is not specified.



## Parameters

<div class="wd-params-table">

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

</div>

## Examples

<pre><code class='javascript'>// 1. Verify that the `handleForm` action is always a POST request.
verifies(only=&quot;handleForm&quot;, post=true);

// 2. Verify that the `edit` action is a GET request, that `userId` exists in `params`, and that it is an integer.
verifies(only=&quot;edit&quot;, get=true, params=&quot;userId&quot;, paramsTypes=&quot;integer&quot;);

// 3. Same as above, but invoke a custom handler function on failure instead of aborting.
verifies(only=&quot;edit&quot;, get=true, params=&quot;userId&quot;, paramsTypes=&quot;integer&quot;, handler=&quot;accessDenied&quot;);

// 4. Same verification, but redirect to the `index` action with a flash error message on failure.
verifies(only=&quot;edit&quot;, get=true, params=&quot;userId&quot;, paramsTypes=&quot;integer&quot;, action=&quot;index&quot;, error=&quot;Invalid userId&quot;);

// 5. Verify that a session variable named `userId` exists for all actions except `login` and `register`.
verifies(except=&quot;login,register&quot;, session=&quot;userId&quot;);

// 6. Verify that the `subscribe` action is an AJAX POST request and that `email` exists in `params` as a valid email address.
verifies(only=&quot;subscribe&quot;, ajax=true, post=true, params=&quot;email&quot;, paramsTypes=&quot;email&quot;);
</code></pre>
