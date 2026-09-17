---
title: validationTypeForProperty()
description: "Returns the validation type for the property."
sidebar:
  label: validationTypeForProperty()
  order: 0
---

## Signature

`validationTypeForProperty()` — returns `any`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns the validation type for the property.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of column to retrieve data for. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get the validation type for a string column (e.g. firstName is varchar)
type = model(&quot;Employee&quot;).validationTypeForProperty(&quot;firstName&quot;);
// type -&gt; &quot;string&quot;

// 2. Get the validation type for a numeric column (e.g. salary is integer)
type = model(&quot;Employee&quot;).validationTypeForProperty(&quot;salary&quot;);
// type -&gt; &quot;numeric&quot;

// 3. Get the validation type for a date column (e.g. hireDate is a date/datetime column)
type = model(&quot;Employee&quot;).validationTypeForProperty(&quot;hireDate&quot;);
// type -&gt; &quot;date&quot;

// 4. Property does not exist on the model — returns &quot;string&quot; as the default
type = model(&quot;Employee&quot;).validationTypeForProperty(&quot;nonExistentProperty&quot;);
// type -&gt; &quot;string&quot;
</code></pre>
