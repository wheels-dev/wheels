---
title: linkTo()
description: "Creates a link to another page in your application. Pass in the name of a route to use your configured routes or a controller/action/key combination. Note: Pass"
sidebar:
  label: linkTo()
  order: 0
---

## Signature

`linkTo()` — returns `any`




## Description

Creates a link to another page in your application. Pass in the name of a route to use your configured routes or a controller/action/key combination. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text content of the link. |
| `confirm` | `string` | yes | — | Pass a message here to cause a JavaScript confirmation dialog box to pop up containing the message. |
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
| `href` | `string` | yes | — | Pass a link to an external site here if you want to bypass the CFWheels routing system altogether and link to an external URL. |

</div>

## Examples

<pre>#linkTo(text=&quot;Log Out&quot;, controller=&quot;account&quot;, action=&quot;logout&quot;)#
-&gt; &lt;a href=&quot;/account/logout&quot;&gt;Log Out&lt;/a&gt;

&lt;!--- If you're already in the `account` controller, CFWheels will assume that's where you want the link to point ---&gt;
#linkTo(text=&quot;Log Out&quot;, action=&quot;logout&quot;)#
-&gt; &lt;a href=&quot;/account/logout&quot;&gt;Log Out&lt;/a&gt;

#linkTo(text=&quot;View Post&quot;, controller=&quot;blog&quot;, action=&quot;post&quot;, key=99)#
-&gt; &lt;a href=&quot;/blog/post/99&quot;&gt;View Post&lt;/a&gt;

#linkTo(text=&quot;View Settings&quot;, action=&quot;settings&quot;, params=&quot;show=all&amp;sort=asc&quot;)#
-&gt; &lt;a href=&quot;/account/settings?show=all&amp;amp;sort=asc&quot;&gt;View Settings&lt;/a&gt;

&lt;!--- Given that a `userProfile` route has been configured in `config/routes.cfm` ---&gt;
#linkTo(text=&quot;Joe's Profile&quot;, route=&quot;userProfile&quot;, userName=&quot;joe&quot;)#
-&gt; &lt;a href=&quot;/user/joe&quot;&gt;Joe's Profile&lt;/a&gt;

&lt;!--- Link to an external website ---&gt;
#linkTo(text=&quot;ColdFusion Framework&quot;, href=&quot;http://cfwheels.org/&quot;)#
-&gt; &lt;a href=&quot;http://cfwheels.org/&quot;&gt;ColdFusion Framework&lt;/a&gt;

&lt;!--- Give the link `class` and `id` attributes ---&gt;
#linkTo(text=&quot;Delete Post&quot;, action=&quot;delete&quot;, key=99, class=&quot;delete&quot;, id=&quot;delete-99&quot;)#
-&gt; &lt;a class=&quot;delete&quot; href=&quot;/blog/delete/99&quot; id=&quot;delete-99&quot;&gt;Delete Post&lt;/a&gt;</pre>
