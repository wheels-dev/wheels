---
title: imageTag()
description: "Returns an <code>img</code> tag."
sidebar:
  label: imageTag()
  order: 0
---

## Signature

`imageTag()` — returns `string`

**Available in:** `controller`
**Category:** Asset Functions

## Description

Returns an <code>img</code> tag.
If the image is stored in the local <code>images</code> folder, the tag will also set the <code>width</code>, <code>height</code>, and <code>alt</code> attributes for you.
You can pass any additional arguments (e.g. <code>class</code>, <code>rel</code>, <code>id</code>), and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `source` | `string` | yes | — | The file name of the image if it's available in the local file system (i.e. ColdFusion will be able to access it). Provide the full URL if the image is on a remote server. |
| `onlyPath` | `boolean` | no | `true` |  |
| `host` | `string` | no | — |  |
| `protocol` | `string` | no | — |  |
| `port` | `numeric` | no | `0` |  |
| `encode` | `boolean` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre>&lt;!--- Outputs an `img` tag for `images/logo.png` ---&gt;
#imageTag(&quot;logo.png&quot;)#

&lt;!--- Outputs an `img` tag for `http://cfwheels.org/images/logo.png` ---&gt;
#imageTag(source=&quot;http://cfwheels.org/images/logo.png&quot;, alt=&quot;ColdFusion on Wheels&quot;)#

&lt;!--- Outputs an `img` tag with the `class` attribute set ---&gt;
#imageTag(source=&quot;logo.png&quot;, class=&quot;logo&quot;)#</pre>
