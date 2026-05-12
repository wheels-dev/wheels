---
title: get()
description: "Returns the current value of a Wheels configuration setting or the default value for a specific function argument. It can be used to inspect global Wheels setti"
sidebar:
  label: get()
  order: 0
---

## Signature

`get()` — returns `any`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Returns the current value of a Wheels configuration setting or the default value for a specific function argument. It can be used to inspect global Wheels settings (like table name prefixes, pagination defaults, or other configuration values) or to check what the default argument would be for a particular Wheels function.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Variable name to get setting for. |
| `functionName` | `string` | no | — | Function name to get setting for. |

</div>

## Examples

<pre><code class='javascript'>1. Get the current value of a global Wheels setting
tablePrefix = get(&quot;tableNamePrefix&quot;);

2. Get the default message for the `validatesConfirmationOf` function
confirmationMessageDefault = get(functionName=&quot;validatesConfirmationOf&quot;, name=&quot;message&quot;);

3. Check the default value for the &quot;null&quot; argument in migrations
allowNullDefault = get(functionName=&quot;float&quot;, name=&quot;null&quot;);

4. Retrieve the current default number of rows per page in pagination
perPageDefault = get(&quot;perPage&quot;);
</code></pre>
