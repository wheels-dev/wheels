---
title: URLFor()
description: "Generates an internal URL based on the supplied arguments. It can create URLs using a named route, or by specifying a controller and action directly. Additional"
sidebar:
  label: URLFor()
  order: 0
---

## Signature

`URLFor()` — returns `string`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Generates an internal URL based on the supplied arguments. It can create URLs using a named route, or by specifying a controller and action directly. Additional options let you include keys, query parameters, anchors, and override protocol, host, or port. By default, the function returns a relative URL, but you can configure it to return a fully qualified URL. URL parameters are automatically encoded for safety, but for HTML attribute safety, further encoding is recommended.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `route` | `string` | no | — | Name of a route that you have configured in `config/routes.cfm`. |
| `controller` | `string` | no | — | Name of the controller to include in the URL. |
| `action` | `string` | no | — | Name of the action to include in the URL. |
| `key` | `any` | no | — | Key(s) to include in the URL. |
| `params` | `string` | no | — | Any additional parameters to be set in the query string (example: `wheels=cool&x=y`). Please note that Wheels uses the `&` and `=` characters to split the parameters and encode them properly for you. However, if you need to pass in `&` or `=` as part of the value, then you need to encode them (and only them), example: `a=cats%26dogs%3Dtrouble!&b=1`. |
| `anchor` | `string` | no | — | Sets an anchor name to be appended to the path. |
| `onlyPath` | `boolean` | no | `true` | If `true`, returns only the relative URL (no protocol, host name or port). |
| `host` | `string` | no | — | Set this to override the current host. |
| `protocol` | `string` | no | — | Set this to override the current protocol. |
| `port` | `numeric` | no | `0` | Set this to override the current port number. |
| `encode` | `boolean` | no | `true` | Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead. |
| `$encodeForHtmlAttribute` | `boolean` | no | `false` |  |
| `$URLRewriting` | `string` | no | `[runtime expression]` |  |

</div>

## Examples

<pre><code class='javascript'>1. Create the URL for the `logOut` action on the `account` controller, typically resulting in `/account/log-out`
#urlFor(controller=&quot;account&quot;, action=&quot;logOut&quot;)#

2. Create a URL with an anchor set on it
#urlFor(action=&quot;comments&quot;, anchor=&quot;comment10&quot;)#

3. Create a URL based on a route called `products`, which expects params for `categorySlug` and `productSlug`
#urlFor(route=&quot;product&quot;, categorySlug=&quot;accessories&quot;, productSlug=&quot;battery-charger&quot;)#</code></pre>
