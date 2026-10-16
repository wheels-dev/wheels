---
title: whereIn()
description: "Constrain a route variable to only match one of a set of allowed values. Similar to an enum constraint."
sidebar:
  label: whereIn()
  order: 0
---

## Signature

`whereIn()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Constrain a route variable to only match one of a set of allowed values. Similar to an enum constraint.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `variableName` | `string` | yes | — | The route variable name to constrain. |
| `values` | `string` | yes | — | A comma-delimited list of allowed values (e.g., `"active,inactive,pending"`). |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    // 1. Constrain a route variable to a fixed set of allowed string values
    //    The [status] segment will only match &quot;active&quot;, &quot;inactive&quot;, or &quot;pending&quot;
    .get(name=&quot;usersByStatus&quot;, pattern=&quot;users/[status]&quot;, to=&quot;users##byStatus&quot;)
    .whereIn(variableName=&quot;status&quot;, values=&quot;active,inactive,pending&quot;)

    // 2. Constrain a locale segment to a known list of supported languages
    //    Requests like /en/home match; /xx/home returns a 404
    .get(name=&quot;localizedHome&quot;, pattern=&quot;[locale]/home&quot;, to=&quot;home##index&quot;)
    .whereIn(variableName=&quot;locale&quot;, values=&quot;en,fr,de,es&quot;)

    // 3. Chain whereIn with whereNumber for mixed-type segment constraints
    //    [type] must be one of the listed values; [id] must be numeric
    .get(name=&quot;typedItem&quot;, pattern=&quot;items/[type]/[id]&quot;, to=&quot;items##show&quot;)
    .whereIn(variableName=&quot;type&quot;, values=&quot;book,magazine,journal&quot;)
    .whereNumber(&quot;id&quot;)
.end();

&lt;/cfscript&gt;
</code></pre>
