---
title: binary()
description: "Adds one or more binary columns to a table definition in a migration. Use this for storing raw binary data, such as files, images, or other byte streams."
sidebar:
  label: binary()
  order: 0
---

## Signature

`binary()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds one or more binary columns to a table definition in a migration. Use this for storing raw binary data, such as files, images, or other byte streams.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>1. Add a single binary column
binary(columnNames="profilePicture");

2. Add multiple binary columns
binary(columnNames="thumbnail, documentBlob");

3. Add a binary column that allows NULLs
binary(columnNames="attachment", allowNull=true);

4. Add a binary column with a default value
binary(columnNames="signature", default="0x00");</code></pre>
