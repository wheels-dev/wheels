---
title: singularize()
description: "Converts a plural word into its singular form. It uses Wheels’ built-in inflection rules, handling common English pluralization cases as well as irregular words"
sidebar:
  label: singularize()
  order: 0
---

## Signature

`singularize()` — returns `string`

**Available in:** `controller`, `model`, `test`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Converts a plural word into its singular form. It uses Wheels’ built-in inflection rules, handling common English pluralization cases as well as irregular words. This is useful when dynamically generating model names, table names, or working with resource naming conventions.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `word` | `string` | yes | — |  |

## Examples

<pre><code class='javascript'>1. Simple plural -&gt; singular
#singularize(&quot;languages&quot;)#

Output:
language

2. Words ending in -ies
#singularize(&quot;companies&quot;)#

Output:
company

3. Words ending in -es
#singularize(&quot;boxes&quot;)#

Output:
box

4. Irregular plural
#singularize(&quot;children&quot;)#

Output:
child</code></pre>
