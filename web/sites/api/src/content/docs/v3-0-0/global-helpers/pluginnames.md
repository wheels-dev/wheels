---
title: pluginNames()
description: "Returns a list of all installed Wheels plugins in your application. This can be useful if you want to check for the presence of a plugin before calling its func"
sidebar:
  label: pluginNames()
  order: 0
---

## Signature

`pluginNames()` — returns `string`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Returns a list of all installed Wheels plugins in your application. This can be useful if you want to check for the presence of a plugin before calling its functionality, or to display available plugins dynamically.




## Examples

<pre><code class='javascript'>1. Check if a specific plugin is installed
&lt;cfif ListFindNoCase(&quot;scaffold&quot;, pluginNames())&gt;
    &lt;cfoutput&gt;
        The Scaffold plugin is installed!
    &lt;/cfoutput&gt;
&lt;cfelse&gt;
    &lt;cfoutput&gt;
        Scaffold plugin is not installed.
    &lt;/cfoutput&gt;
&lt;/cfif&gt;

2. List all installed plugins
&lt;cfoutput&gt;
Installed Plugins: #pluginNames()#
&lt;/cfoutput&gt;

3. Loop through all installed plugins
&lt;cfloop list=&quot;#pluginNames()#&quot; index=&quot;plugin&quot;&gt;
    &lt;cfoutput&gt;
        Plugin: #plugin#&lt;br&gt;
    &lt;/cfoutput&gt;
&lt;/cfloop&gt;

4. Conditional logic based on multiple plugins
&lt;cfset plugins = pluginNames()&gt;

&lt;cfif ListFindNoCase(&quot;scaffold&quot;, plugins) AND ListFindNoCase(&quot;seo&quot;, plugins)&gt;
    &lt;cfoutput&gt;
        Both Scaffold and SEO plugins are installed.
    &lt;/cfoutput&gt;
&lt;/cfif&gt;
</code></pre>
