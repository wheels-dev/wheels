---
title: pluginNames()
description: "Returns a list of all installed plugins' names."
sidebar:
  label: pluginNames()
  order: 0
---

## Signature

`pluginNames()` — returns `any`




## Description

Returns a list of all installed plugins' names.


## Examples

<pre>pluginNames() &lt;!--- Check if the Scaffold plugin is installed ---&gt;
&lt;cfif ListFindNoCase(&quot;scaffold&quot;, pluginNames())&gt;
    &lt;!--- do something cool ---&gt;
&lt;/cfif&gt;</pre>
