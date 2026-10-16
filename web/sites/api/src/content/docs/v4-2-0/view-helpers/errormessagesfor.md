---
title: errorMessagesFor()
description: "Builds and returns a list (<code>ul</code> tag with a default <code>class</code> of <code>error-messages</code>) containing all the error messages for all the p"
sidebar:
  label: errorMessagesFor()
  order: 0
---

## Signature

`errorMessagesFor()` — returns `string`

**Available in:** `controller`
**Category:** Error Functions

## Description

Builds and returns a list (<code>ul</code> tag with a default <code>class</code> of <code>error-messages</code>) containing all the error messages for all the properties of the object.
Returns an empty string if no errors exist.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `string` | yes | — | The variable name of the object to display error messages for. |
| `class` | `string` | no | `error-messages` | CSS `class` to set on the `ul` element. |
| `showDuplicates` | `boolean` | no | `true` | Whether or not to show duplicate error messages. |
| `encode` | `boolean` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |
| `includeAssociations` | `boolean` | no | `true` |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Display all error messages for a user object
#errorMessagesFor(objectName=&quot;user&quot;)#
// -&gt; &lt;ul class=&quot;error-messages&quot;&gt;&lt;li&gt;Email is not a valid email address.&lt;/li&gt;&lt;li&gt;Username can't be blank.&lt;/li&gt;&lt;/ul&gt;
// -&gt; (empty string when the object has no errors)

// 2. Use a custom CSS class on the wrapping ul element
#errorMessagesFor(objectName=&quot;user&quot;, class=&quot;form-errors&quot;)#
// -&gt; &lt;ul class=&quot;form-errors&quot;&gt;&lt;li&gt;Email is not a valid email address.&lt;/li&gt;&lt;/ul&gt;

// 3. Suppress duplicate error messages
#errorMessagesFor(objectName=&quot;user&quot;, showDuplicates=false)#
// -&gt; &lt;ul class=&quot;error-messages&quot;&gt;&lt;li&gt;can't be blank.&lt;/li&gt;&lt;/ul&gt;
// (only one &quot;can't be blank.&quot; entry even if multiple fields have the same message)

// 4. Include errors from associated objects as well
#errorMessagesFor(objectName=&quot;order&quot;, includeAssociations=true)#
// -&gt; &lt;ul class=&quot;error-messages&quot;&gt;&lt;li&gt;Name can't be blank.&lt;/li&gt;&lt;li&gt;Line items quantity must be greater than zero.&lt;/li&gt;&lt;/ul&gt;
</code></pre>
