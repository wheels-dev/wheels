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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `quoted` | `boolean` | no | `false` | Set to `true` to enclose each value in single-quotation marks. |
| `delimiter` | `string` | no | `,` | The delimiter character to separate the list items with. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get a comma-delimited list of all primary key values for the Artist model
primaryKeyList = model(&quot;artist&quot;).findAllKeys();
// primaryKeyList -&gt; &quot;1,2,3,4,5&quot;

// 2. Get keys for active artists only, enclosed in single quotes, separated by a pipe
primaryKeyList = model(&quot;artist&quot;).findAllKeys(quoted=true, delimiter=&quot;|&quot;, where=&quot;active=1&quot;);
// primaryKeyList -&gt; &quot;'1'|'3'|'5'&quot;

// 3. Use the result directly in a SQL IN clause for a subsequent query
keyList = model(&quot;artist&quot;).findAllKeys(quoted=true, where=&quot;genreId=7&quot;);
albums = model(&quot;album&quot;).findAll(where=&quot;artistId IN (#keyList#)&quot;);
</code></pre>
