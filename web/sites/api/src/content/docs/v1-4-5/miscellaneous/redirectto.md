---
title: redirectTo()
description: "Redirects the browser to the supplied controller/action/key, route or back to the referring page. Internally, this function uses the URLFor function to build th"
sidebar:
  label: redirectTo()
  order: 0
---

## Signature

`redirectTo()` — returns `any`




## Description

Redirects the browser to the supplied controller/action/key, route or back to the referring page. Internally, this function uses the URLFor function to build the link and the cflocation tag to perform the redirect.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `back` | `boolean` | yes | `false` | Set to true to redirect back to the referring page. |
| `addToken` | `boolean` | yes | `false` | See documentation for your CFML engine's implementation of cflocation. |
| `statusCode` | `numeric` | yes | `302` | See documentation for your CFML engine's implementation of cflocation. |
| `route` | `string` | yes | — | Name of a route that you have configured in config/routes.cfm. |
| `controller` | `string` | yes | — | Name of the controller to include in the URL. |
| `action` | `string` | yes | — | Name of the action to include in the URL. |
| `key` | `any` | yes | — | Key(s) to include in the URL. |
| `params` | `string` | yes | — | Any additional parameters to be set in the query string (example: wheels=cool&x=y). Please note that CFWheels uses the & and = characters to split the parameters and encode them properly for you (using URLEncodedFormat() internally). However, if you need to pass in & or = as part of the value, then you need to encode them (and only them), example: a=cats%26dogs%3Dtrouble!&b=1. |
| `anchor` | `string` | yes | — | Sets an anchor name to be appended to the path. |
| `onlyPath` | `boolean` | yes | `true` | If true, returns only the relative URL (no protocol, host name or port). |
| `host` | `string` | yes | — | Set this to override the current host. |
| `protocol` | `string` | yes | — | Set this to override the current protocol. |
| `port` | `numeric` | yes | `0` | Set this to override the current port number. |
| `url` | `string` | yes | — | Redirect to an external URL. |
| `delay` | `boolean` | yes | `false` | Set to true to delay the redirection until after the rest of your action code has executed. |

</div>

## Examples

<pre>// Redirect to an action after successfully saving a user
if (user.save())
{
	redirectTo(action=&quot;saveSuccessful&quot;);
}

// Redirect to a specific page on a secure server
redirectTo(controller=&quot;checkout&quot;, action=&quot;start&quot;, params=&quot;type=express&quot;, protocol=&quot;https&quot;);

// Redirect to a route specified in `config/routes.cfm` and pass in the screen name that the route takes
redirectTo(route=&quot;profile&quot;, screenName=&quot;Joe&quot;);

// Redirect back to the page the user came from
redirectTo(back=true);</pre>
