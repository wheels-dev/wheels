---
title: accessibleProperties()
description: "Use this method inside your model’s config() function to whitelist which properties can be set via mass assignment operations (such as updateAll(), updateOne()"
sidebar:
  label: accessibleProperties()
  order: 0
---

## Signature

`accessibleProperties()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Use this method inside your model’s config() function to whitelist which properties can be set via mass assignment operations (such as updateAll(), updateOne() and etc). This helps protect your model from accidental or malicious updates to sensitive fields (e.g., isAdmin, passwordHash, etc.).



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Property name (or list of property names) that are allowed to be altered through mass assignment. |

## Examples

<pre><code class='javascript'>1. Allow only one property
// In app/models/User.cfc
function config() {
    // Only allow `isActive` to be set through mass assignment
    accessibleProperties(&quot;isActive&quot;);
}

// Example usage
User.updateAll(isActive=true);

2. Allow multiple properties
// In app/models/User.cfc
function config() {
    // Allow name and email to be set
    accessibleProperties(&quot;firstName,lastName,email&quot;);
}

// Example usage
User.create(firstName=&quot;new&quot;, lastName=&quot;user&quot;, email=&quot;new@example.com&quot;);

3. Dynamic restriction per model
// In app/models/Post.cfc
function config() {
    if (application.env.environment == &quot;production&quot;) {
        // Lock down sensitive fields in production
        accessibleProperties(&quot;title,content&quot;);
    } else {
        // In dev, keep it open for testing
    }
}</code></pre>
