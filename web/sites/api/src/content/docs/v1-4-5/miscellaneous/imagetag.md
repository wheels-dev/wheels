---
title: imageTag()
description: "Returns an img tag. If the image is stored in the local images folder, the tag will also set the width, height, and alt attributes for you. Note: Pass any addit"
sidebar:
  label: imageTag()
  order: 0
---

## Signature

`imageTag()` — returns `any`




## Description

Returns an img tag. If the image is stored in the local images folder, the tag will also set the width, height, and alt attributes for you. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `source` | `string` | yes | — | The file name of the image if it's available in the local file system (i.e. ColdFusion will be able to access it). Provide the full URL if the image is on a remote server. |

## Examples

<pre>imageTag(source) &lt;!--- Outputs an `img` tag for `images/logo.png` ---&gt;
#imageTag(&quot;logo.png&quot;)#

&lt;!--- Outputs an `img` tag for `http://cfwheels.org/images/logo.png` ---&gt;
#imageTag(source=&quot;http://cfwheels.org/images/logo.png&quot;, alt=&quot;ColdFusion on Wheels&quot;)#

&lt;!--- Outputs an `img` tag with the `class` attribute set ---&gt;
#imageTag(source=&quot;logo.png&quot;, class=&quot;logo&quot;)#</pre>
