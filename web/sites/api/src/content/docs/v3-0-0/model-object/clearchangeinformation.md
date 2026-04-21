---
title: clearChangeInformation()
description: "Clears all internal tracking information that Wheels maintains about an object’s properties. This does not undo changes made to the object—it simply resets the"
sidebar:
  label: clearChangeInformation()
  order: 0
---

## Signature

`clearChangeInformation()` — returns `void`

**Available in:** `model`
**Category:** Change Functions

## Description

Clears all internal tracking information that Wheels maintains about an object’s properties. This does not undo changes made to the object—it simply resets the record of which properties are considered “changed,” so methods like hasChanged(), changedProperties(), or allChanges() will no longer report them. This is useful when you modify a property programmatically (for example, in a callback) and don’t want Wheels to attempt saving or reporting it as a change.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | string false Name of property to clear information for. |

</div>

## Examples

<pre><code class='javascript'>1. Clear change information for a single property
// Convert startTime to UTC in an "afterFind" callback
this.startTime = DateConvert("Local2UTC", this.startTime);

// Tell Wheels to clear internal change tracking for this property
this.clearChangeInformation(property="startTime");

2. Clear change information for all properties
// Clear internal tracking for all properties of the object
this.clearChangeInformation();</code></pre>
