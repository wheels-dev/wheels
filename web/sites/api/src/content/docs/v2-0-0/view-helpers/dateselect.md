---
title: dateSelect()
description: "Builds and returns a string containing three <code>select</code> form controls for month, day, and year based on the supplied <code>objectName</code> and <code>"
sidebar:
  label: dateSelect()
  order: 0
---

## Signature

`dateSelect()` — returns `string`

**Available in:** `controller`
**Category:** Form Object Functions

## Description

Builds and returns a string containing three <code>select</code> form controls for month, day, and year based on the supplied <code>objectName</code> and <code>property</code>.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | no | — | The variable name of the object to build the form control for. |
| `property` | `string` | no | — | The name of the property to use in the form control. |
| `association` | `string` | no | — | The name of the association that the property is located on. Used for building nested forms that work with nested properties. If you are building a form with deep nesting, simply pass in a list to the nested object, and CFWheels will figure it out. |
| `position` | `string` | no | — | The position used when referencing a `hasMany` relationship in the association argument. Used for building nested forms that work with nested properties. If you are building a form with deep nestings, simply pass in a list of positions, and CFWheels will figure it out. |
| `order` | `string` | no | `month,day,year` | Use to change the order of or exclude date `select` tags. |
| `separator` | `string` | no | ` ` |  |
| `startYear` | `numeric` | no | `2012` | First year in `select` list. |
| `endYear` | `numeric` | no | `2022` | Last year in `select` list. |
| `monthDisplay` | `string` | no | `names` | Pass in names, numbers, or abbreviations to control display. |
| `monthNames` | `string` | no | `January,February,March,April,May,June,July,August,September,October,November,December` |  |
| `monthAbbreviations` | `string` | no | `Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec` |  |
| `includeBlank` | `any` | no | `false` | Whether to include a blank option in the `select` form control. Pass `true` to include a blank line or a string that should represent what display text should appear for the empty value (for example, "- Select One -"). |
| `label` | `string` | no | `false` | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using `aroundLeft` or `aroundRight`. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `errorElement` | `string` | no | `span` | HTML tag to wrap the form control with when the object contains errors. |
| `errorClass` | `string` | no | `field-with-errors` | The `class` name of the HTML tag that wraps the form control when there are errors. |
| `combine` | `boolean` | no | — | Set to false to not combine the select parts into a single DateTime object. |
| `encode` | `any` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre>&lt;!--- View code ---&gt;
#dateSelect(objectName=&quot;user&quot;, property=&quot;dateOfBirth&quot;)#

&lt;!--- Show fields to select month and year ---&gt;
#dateSelect(objectName=&quot;order&quot;, property=&quot;expirationDate&quot;, order=&quot;month,year&quot;)#</pre>
