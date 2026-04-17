---
title: urlFor()
description: "Creates an internal URL based on supplied arguments."
sidebar:
  label: urlFor()
  order: 0
---

## Signature

`urlFor()` — returns `any`




## Description

Creates an internal URL based on supplied arguments.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
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

## Examples

<pre>urlFor([ route, controller, action, key, params, anchor, onlyPath, host, protocol, port ]) &lt;!--- Create the URL for the `logOut` action on the `account` controller, typically resulting in `/account/log-out` ---&gt;
#urlFor(controller=&quot;account&quot;, action=&quot;logOut&quot;)#

&lt;!--- Create a URL with an anchor set on it ---&gt;
#urlFor(action=&quot;comments&quot;, anchor=&quot;comment10&quot;)#

&lt;!--- Create a URL based on a route called `products`, which expects params for `categorySlug` and `productSlug` ---&gt;
#urlFor(route=&quot;product&quot;, categorySlug=&quot;accessories&quot;, productSlug=&quot;battery-charger&quot;)#</pre>
