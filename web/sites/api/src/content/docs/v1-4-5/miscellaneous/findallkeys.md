---
title: findAllKeys()
description: "Returns all primary key values in a list. In addition to quoted and delimiter you can pass in any argument that findAll() accepts."
sidebar:
  label: findAllKeys()
  order: 0
---

## Signature

`findAllKeys()` — returns `any`




## Description

Returns all primary key values in a list. In addition to quoted and delimiter you can pass in any argument that findAll() accepts.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `quoted` | `boolean` | yes | `false` | Set to true to enclose each value in single-quotation marks. |
| `delimiter` | `string` | yes | `,` | The delimiter character to separate the list items with. |

</div>

## Examples

<pre>// basic usage
primaryKeyList = model(&quot;artist&quot;).findAllKeys();

// Quote values, use a different delimiter and filter results with the &quot;where&quot; argument
primaryKeyList = model(&quot;artist&quot;).findAllKeys(quoted=true, delimiter=&quot;-&quot;, where=&quot;active=1&quot;);</pre>
