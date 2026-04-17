---
title: autoLink()
description: "Scans a block of text for URLs and/or email addresses and automatically converts them into clickable links. This helper is handy for displaying user-generated c"
sidebar:
  label: autoLink()
  order: 0
---

## Signature

`autoLink()` — returns `string`

**Available in:** `controller`
**Category:** Link Functions

## Description

Scans a block of text for URLs and/or email addresses and automatically converts them into clickable links. This helper is handy for displaying user-generated content, comments, or messages where you want to make links interactive without manually adding <a> tags.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to create links in. |
| `link` | `string` | no | `all` | Whether to link URLs, email addresses or both. Possible values are: `all` (default), `URLs` and `emailAddresses`. |
| `relative` | `boolean` | no | `true` | Should we auto-link relative urls. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre><code class='javascript'>1. Auto-link a URL
#autoLink("Download Wheels from https://wheels.dev")#

Output:

Download Wheels from &lt;a href="https://wheels.dev"&gt;https://wheels.dev&lt;/a&gt;

2. Auto-link an email address
#autoLink("Email us at info@cfwheels.org")#

Output:

Email us at &lt;a href="mailto:info@cfwheels.org"&gt;info@cfwheels.org&lt;/a&gt;

3. Only link URLs, not emails
#autoLink(text="Visit https://cfwheels.org or email support@cfwheels.org", link="URLs")#

Output:

Visit &lt;a href="https://cfwheels.org"&gt;https://cfwheels.org&lt;/a&gt; or email support@cfwheels.org

4. Only link email addresses
#autoLink(text="Contact info@cfwheels.org or see https://cfwheels.org", link="emailAddresses")#

Output:

Contact &lt;a href="mailto:info@cfwheels.org"&gt;info@cfwheels.org&lt;/a&gt; or see https://cfwheels.org

5. Disable auto-linking of relative URLs
#autoLink(text="See /about for more info", relative=false)#

Output:

See /about for more info</code></pre>
