---
title: pluginNames()
description: "Returns a list of the names of all installed plugins."
sidebar:
  label: pluginNames()
  order: 0
---

## Signature

`pluginNames()` — returns `string`

**Available in:** `controller`, `model`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Returns a list of the names of all installed plugins.




## Examples

<pre><code class='javascript'>// Check if the Scaffold plugin is installed 
&lt;cfif ListFindNoCase(&quot;scaffold&quot;, pluginNames())&gt;
    // do something cool 
&lt;/cfif&gt;</code></pre>
