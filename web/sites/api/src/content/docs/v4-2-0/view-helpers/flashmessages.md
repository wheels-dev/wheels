---
title: flashMessages()
description: "Displays a marked-up listing of messages that exist in the Flash."
sidebar:
  label: flashMessages()
  order: 0
---

## Signature

`flashMessages()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Displays a marked-up listing of messages that exist in the Flash.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `keys` | `string` | no | — | The key (or list of keys) to show the value for. You can also use the `key` argument instead for better readability when accessing a single key. |
| `class` | `string` | no | `flash-messages` | HTML `class` to set on the `div` element that contains the messages. |
| `includeEmptyContainer` | `boolean` | no | `false` | Includes the `div` container even if the Flash is empty. |
| `encode` | `boolean` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>// 1. Display all Flash messages in a view
// In the controller action:
flashInsert(success=&quot;Your post was successfully submitted.&quot;);
flashInsert(alert=&quot;Don't forget to tweet about this post!&quot;);
flashInsert(error=&quot;This is an error message.&quot;);

// In the layout or view:
writeOutput(flashMessages());

// Generates (keys sorted alphabetically):
// &lt;div class=&quot;flash-messages&quot;&gt;
//   &lt;p class=&quot;alert-message&quot;&gt;Don't forget to tweet about this post!&lt;/p&gt;
//   &lt;p class=&quot;error-message&quot;&gt;This is an error message.&lt;/p&gt;
//   &lt;p class=&quot;success-message&quot;&gt;Your post was successfully submitted.&lt;/p&gt;
// &lt;/div&gt;


// 2. Show only a single Flash key using the `key` alias
writeOutput(flashMessages(key=&quot;success&quot;));

// Generates:
// &lt;div class=&quot;flash-messages&quot;&gt;
//   &lt;p class=&quot;success-message&quot;&gt;Your post was successfully submitted.&lt;/p&gt;
// &lt;/div&gt;


// 3. Show a specific set of keys in a defined order using `keys`
writeOutput(flashMessages(keys=&quot;success,alert&quot;));

// Generates (in the order supplied, not alphabetically):
// &lt;div class=&quot;flash-messages&quot;&gt;
//   &lt;p class=&quot;success-message&quot;&gt;Your post was successfully submitted.&lt;/p&gt;
//   &lt;p class=&quot;alert-message&quot;&gt;Don't forget to tweet about this post!&lt;/p&gt;
// &lt;/div&gt;


// 4. Always render the container div, even when the Flash is empty
writeOutput(flashMessages(includeEmptyContainer=true));

// Generates:
// &lt;div class=&quot;flash-messages&quot;&gt;&lt;/div&gt;


// 5. Use a custom CSS class on the outer container
writeOutput(flashMessages(class=&quot;notifications&quot;));

// Generates:
// &lt;div class=&quot;notifications&quot;&gt;
//   &lt;p class=&quot;alert-message&quot;&gt;Don't forget to tweet about this post!&lt;/p&gt;
//   &lt;p class=&quot;error-message&quot;&gt;This is an error message.&lt;/p&gt;
//   &lt;p class=&quot;success-message&quot;&gt;Your post was successfully submitted.&lt;/p&gt;
// &lt;/div&gt;
</code></pre>
