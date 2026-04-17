---
title: findAllKeys()
description: "Returns all primary key values in a list."
sidebar:
  label: findAllKeys()
  order: 0
---

## Signature

`findAllKeys()` — returns `string`

**Available in:** `model`
**Category:** Read Functions

## Description

Returns all primary key values in a list.
In addition to <code>quoted</code> and <code>delimiter</code> you can pass in any argument that <code>findAll()</code> accepts.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `quoted` | `boolean` | no | `false` | Set to `true` to enclose each value in single-quotation marks. |
| `delimiter` | `string` | no | `,` | The delimiter character to separate the list items with. |

## Examples

<pre><code class='javascript'>// basic usage
primaryKeyList = model(&quot;artist&quot;).findAllKeys();

// Quote values, use a different delimiter and filter results with the &quot;where&quot; argument
primaryKeyList = model(&quot;artist&quot;).findAllKeys(quoted=true, delimiter=&quot;-&quot;, where=&quot;active=1&quot;);</code></pre>
