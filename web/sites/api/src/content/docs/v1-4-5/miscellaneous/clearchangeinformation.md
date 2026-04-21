---
title: clearChangeInformation()
description: "Clears all internal knowledge of the current state of the object."
sidebar:
  label: clearChangeInformation()
  order: 0
---

## Signature

`clearChangeInformation()` — returns `any`




## Description

Clears all internal knowledge of the current state of the object.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to clear information for. |

</div>

## Examples

<pre>// Convert startTime to UTC (maybe done in an &quot;after find&quot; call back) but then tell CFWheels to clear the information about this change (but not the change itself) so that it won't attempt to save the new value to the database, report it as being changed when calling hasChanged() etc.

this.startTime = DateConvert(&quot;Local2UTC&quot;, this.startTime);
this.clearChangeInformation(property=&quot;startTime&quot;);

// Clear information for all properties
this.clearChangeInformation();</pre>
