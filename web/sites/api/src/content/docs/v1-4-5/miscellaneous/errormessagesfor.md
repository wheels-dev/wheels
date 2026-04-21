---
title: errorMessagesFor()
description: "Builds and returns a list (ul tag with a default class of errorMessages) containing all the error messages for all the properties of the object (if any). Return"
sidebar:
  label: errorMessagesFor()
  order: 0
---

## Signature

`errorMessagesFor()` — returns `any`




## Description

Builds and returns a list (ul tag with a default class of errorMessages) containing all the error messages for all the properties of the object (if any). Returns an empty string otherwise.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `string` | yes | — | The variable name of the object to display error messages for. |
| `class` | `string` | yes | `errorMessage` | CSS class to set on the ul element. |
| `showDuplicates` | `boolean` | yes | `true` | Whether or not to show duplicate error messages. |

</div>

## Examples

<pre>errorMessagesFor(objectName [, class, showDuplicates ]) &lt;!--- view code ---&gt;
&lt;cfoutput&gt;
    #errorMessagesFor(objectName=&quot;user&quot;)#
&lt;/cfoutput&gt;</pre>
