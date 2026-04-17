---
title: findOrCreateBy[Property]()
description: "Returns the object or creates a new one if it wasn't found."
sidebar:
  label: findOrCreateBy[Property]()
  order: 0
---

## Signature

`findOrCreateBy[Property]()` — returns `any`




## Description

Returns the object or creates a new one if it wasn't found.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `save` | `boolean` | yes | `true` | Passing in false will create the object without saving it to the database. |

## Examples

<pre>// Return the first object that matches &quot;Timberlake&quot; in the last name column. If there is no match, create a new one and set firstName to &quot;Justin&quot;.
newArtist = model(&quot;artist&quot;).findOrCreateByLastName(lastName=&quot;Timberlake&quot;, firstName=&quot;Justin&quot;);</pre>
