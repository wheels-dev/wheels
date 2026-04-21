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
| `encode` | `boolean` | no | `true` | Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead. |
| `includeAssociations` | `boolean` | no | `true` |  |

</div>

## Examples

<pre><code class='javascript'>Example 1 — Basic usage
&lt;cfoutput&gt;
#errorMessagesFor(objectName=&quot;author&quot;)#
&lt;/cfoutput&gt;

Generates a &lt;ul class=&quot;error-messages&quot;&gt; containing all errors for the author object.

Default behavior includes all associated object errors.

Example 2 — Custom CSS class
&lt;cfoutput&gt;
#errorMessagesFor(objectName=&quot;author&quot;, class=&quot;alert alert-danger&quot;)#
&lt;/cfoutput&gt;

Uses a custom CSS class for styling (e.g., Bootstrap alerts).

Example 3 — Exclude duplicate errors
&lt;cfoutput&gt;
#errorMessagesFor(objectName=&quot;author&quot;, showDuplicates=false)#
&lt;/cfoutput&gt;

Prevents duplicate messages from appearing multiple times in the list.

Example 4 — Include or exclude associated objects
&lt;cfoutput&gt;
&lt;!--- Only show errors on this object, not on associated objects ---&gt;
#errorMessagesFor(objectName=&quot;author&quot;, includeAssociations=false)#
&lt;/cfoutput&gt;

Useful if you want to display errors for the main object separately from associated objects (like a nested profile or address).

Example 5 — HTML encoding disabled
&lt;cfoutput&gt;
#errorMessagesFor(objectName=&quot;author&quot;, encode=false)#
&lt;/cfoutput&gt;

Errors are output as-is, allowing embedded HTML in the messages (use with caution).
</code></pre>
