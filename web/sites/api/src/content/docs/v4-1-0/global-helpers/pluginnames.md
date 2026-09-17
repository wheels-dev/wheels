---
title: pluginNames()
description: "Returns a list of the names of all installed plugins."
sidebar:
  label: pluginNames()
  order: 0
---

## Signature

`pluginNames()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Returns a list of the names of all installed plugins.




## Examples

<pre><code class='javascript'>// 1. Check if the Scaffold plugin is installed
&lt;cfif listFindNoCase(pluginNames(), &quot;scaffold&quot;)&gt;
    // do something cool
&lt;/cfif&gt;

// 2. Output all installed plugin names
names = pluginNames();
// names -&gt; &quot;scaffold,formobject,myplugin&quot; (comma-separated list of installed plugin names)

// 3. Loop over installed plugins
&lt;cfloop list=&quot;#pluginNames()#&quot; index=&quot;pluginName&quot;&gt;
    writeOutput(pluginName);
&lt;/cfloop&gt;
</code></pre>
