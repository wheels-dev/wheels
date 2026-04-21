---
title: linkTo()
description: "Creates a link to another page in your application."
sidebar:
  label: linkTo()
  order: 0
---

## Signature

`linkTo()` — returns `string`

**Available in:** `controller`
**Category:** Link Functions

## Description

Creates a link to another page in your application.
Pass in the name of a route to use your configured routes or a controller/action/key combination.
Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | no | — | The text content of the link. |
| `route` | `string` | no | — | Name of a route that you have configured in config/routes.cfm. |
| `controller` | `string` | no | — | Name of the controller to include in the URL. |
| `action` | `string` | no | — | Name of the action to include in the URL. |
| `key` | `any` | no | — | Key(s) to include in the URL. |
| `params` | `string` | no | — | Any additional parameters to be set in the query string (example: wheels=cool&x=y). Please note that CFWheels uses the & and = characters to split the parameters and encode them properly for you. However, if you need to pass in & or = as part of the value, then you need to encode them (and only them), example: a=cats%26dogs%3Dtrouble!&b=1. |
| `anchor` | `string` | no | — | Sets an anchor name to be appended to the path. |
| `onlyPath` | `boolean` | no | `true` | If true, returns only the relative URL (no protocol, host name or port). |
| `host` | `string` | no | — | Set this to override the current host. |
| `protocol` | `string` | no | — | Set this to override the current protocol. |
| `port` | `numeric` | no | `0` | Set this to override the current port number. |
| `href` | `string` | no | — | Pass a link to an external site here if you want to bypass the CFWheels routing system altogether and link to an external URL. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>#linkTo(text=&quot;Log Out&quot;, controller=&quot;account&quot;, action=&quot;logout&quot;)#
&lt;!--- Ouputs: &lt;a href=&quot;/account/logout&quot;&gt;Log Out&lt;/a&gt; ---&gt;

&lt;!--- If you're already in the `account` controller, CFWheels will assume that's where you want the link to point ---&gt;
#linkTo(text=&quot;Log Out&quot;, action=&quot;logout&quot;)#
&lt;!--- Ouputs: &lt;a href=&quot;/account/logout&quot;&gt;Log Out&lt;/a&gt; ---&gt;

#linkTo(text=&quot;View Post&quot;, controller=&quot;blog&quot;, action=&quot;post&quot;, key=99)#
&lt;!--- Ouputs: &lt;a href=&quot;/blog/post/99&quot;&gt;View Post&lt;/a&gt; ---&gt;

#linkTo(text=&quot;View Settings&quot;, action=&quot;settings&quot;, params=&quot;show=all&amp;amp;sort=asc&quot;)#
&lt;!--- Ouputs: &lt;a href=&quot;/account/settings?show=all&amp;amp;amp;sort=asc&quot;&gt;View Settings&lt;/a&gt; ---&gt;

&lt;!--- Given that a `userProfile` route has been configured in `config/routes.cfm` ---&gt;
#linkTo(text=&quot;Joe's Profile&quot;, route=&quot;userProfile&quot;, userName=&quot;joe&quot;)#
&lt;!--- Ouputs: &lt;a href=&quot;/user/joe&quot;&gt;Joe's Profile&lt;/a&gt; ---&gt;

&lt;!--- Link to an external website ---&gt;
#linkTo(text=&quot;ColdFusion Framework&quot;, href=&quot;http://cfwheels.org/&quot;)#
&lt;!--- Ouputs: &lt;a href=&quot;http://cfwheels.org/&quot;&gt;ColdFusion Framework&lt;/a&gt; ---&gt;

&lt;!--- Give the link `class` and `id` attributes ---&gt;
#linkTo(text=&quot;Delete Post&quot;, action=&quot;delete&quot;, key=99, class=&quot;delete&quot;, id=&quot;delete-99&quot;)#
&lt;!--- Ouputs: &lt;a class=&quot;delete&quot; href=&quot;/blog/delete/99&quot; id=&quot;delete-99&quot;&gt;Delete Post&lt;/a&gt; ---&gt;

</code></pre>
