---
title: redirectTo()
description: "Redirects the browser to the supplied controller/action/key, route or back to the referring page."
sidebar:
  label: redirectTo()
  order: 0
---

## Signature

`redirectTo()` — returns `void`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Redirects the browser to the supplied controller/action/key, route or back to the referring page.
Internally, this function uses the <code>URLFor</code> function to build the link and the <code>cflocation</code> tag to perform the redirect.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `back` | `boolean` | no | `false` | Set to `true` to redirect back to the referring page. |
| `addToken` | `boolean` | no | `false` | See documentation for your CFML engine's implementation of `cflocation`. |
| `statusCode` | `numeric` | no | `302` | See documentation for your CFML engine's implementation of `cflocation`. |
| `route` | `string` | no | — | Name of a route that you have configured in `config/routes.cfm`. |
| `method` | `string` | no | — |  |
| `controller` | `string` | no | — | Name of the controller to include in the URL. |
| `action` | `string` | no | — | Name of the action to include in the URL. |
| `key` | `any` | no | — | Key(s) to include in the URL. |
| `params` | `string` | no | — | Any additional parameters to be set in the query string (example: `wheels=cool&x=y`). Please note that CFWheels uses the `&` and `=` characters to split the parameters and encode them properly for you. However, if you need to pass in `&` or `=` as part of the value, then you need to encode them (and only them), example: `a=cats%26dogs%3Dtrouble!&b=1`. |
| `anchor` | `string` | no | — | Sets an anchor name to be appended to the path. |
| `onlyPath` | `boolean` | no | `true` | If `true`, returns only the relative URL (no protocol, host name or port). |
| `host` | `string` | no | — | Set this to override the current host. |
| `protocol` | `string` | no | — | Set this to override the current protocol. |
| `port` | `numeric` | no | `0` | Set this to override the current port number. |
| `url` | `string` | no | — | Redirect to an external URL. |
| `delay` | `boolean` | no | `false` | Set to `true` to delay the redirection until after the rest of your action code has executed. |
| `encode` | `boolean` | no | `true` | Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead. |

## Examples

<pre><code class='javascript'>// Redirect to an action after successfully saving a user.
if (user.save()) {
	redirectTo(action=&quot;saveSuccessful&quot;);
}

// Redirect to a specific page on a secure server.
redirectTo(controller=&quot;checkout&quot;, action=&quot;start&quot;, params=&quot;type=express&quot;, protocol=&quot;https&quot;);

// Redirect to a route specified in `config/routes.cfm` and pass in the screen name that the route takes.
redirectTo(route=&quot;profile&quot;, screenName=&quot;Joe&quot;);

// Redirect back to the page the user came from.
redirectTo(back=true);
</code></pre>
