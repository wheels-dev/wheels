---
title: scope()
description: "The scope() function in Wheels is used to define a block of routes that share common parameters such as controller, package, path, or naming prefixes. All route"
sidebar:
  label: scope()
  order: 0
---

## Signature

`scope()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

The scope() function in Wheels is used to define a block of routes that share common parameters such as controller, package, path, or naming prefixes. All routes defined inside a scope() block automatically inherit these parameters unless explicitly overridden, making it easier to manage related routes. This is particularly useful for grouping routes under the same controller or package, adding a common URL prefix to multiple routes, applying shallow routing to nested resources, and reducing repetition while improving the maintainability of route definitions.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | — | Name to prepend to child route names for use when building links, forms, and other URLs. |
| `path` | `string` | no | — | Path to prefix to all child routes. |
| `package` | `string` | no | — | Package namespace to append to controllers. |
| `controller` | `string` | no | — | Controller to use for routes. |
| `shallow` | `boolean` | no | — | Turn on shallow resources to eliminate routing added before this one. |
| `shallowPath` | `string` | no | — | Shallow path prefix. |
| `shallowName` | `string` | no | — | Shallow name prefix. |
| `constraints` | `struct` | no | — | Variable patterns to use for matching. |
| `$call` | `string` | no | `scope` |  |

</div>

## Examples

<pre><code class='javascript'>1. Set a default controller for multiple routes

&lt;cfscript&gt;
mapper()
    .scope(controller=&quot;freeForAll&quot;)
        .get(name=&quot;bananas&quot;, action=&quot;bananas&quot;)
        .root(action=&quot;index&quot;)
    .end()
.end();
&lt;/cfscript&gt;

2. Apply a package/subfolder to multiple resources

&lt;cfscript&gt;
mapper()
    .scope(package=&quot;public&quot;)
        .resource(name=&quot;search&quot;, only=&quot;show,create&quot;)
    .end()
.end();
&lt;/cfscript&gt;

3. Add a common URL path prefix

&lt;cfscript&gt;
mapper()
    .scope(path=&quot;phones&quot;)
        .get(name=&quot;newest&quot;, to=&quot;phones##newest&quot;)
        .get(name=&quot;sortOfNew&quot;, to=&quot;phones##sortOfNew&quot;)
    .end()
.end();
&lt;/cfscript&gt;

4. Combine controller and path scoping

&lt;cfscript&gt;
mapper()
    .scope(controller=&quot;products&quot;, path=&quot;shop&quot;)
        .get(name=&quot;featured&quot;, action=&quot;featured&quot;)
        .get(name=&quot;sale&quot;, action=&quot;sale&quot;)
    .end()
.end();
&lt;/cfscript&gt;

5. Use constraints for route variables

&lt;cfscript&gt;
mapper()
    .scope(path=&quot;users&quot;, constraints={userId=&quot;\d+&quot;})
        .get(name=&quot;profile&quot;, pattern=&quot;[userId]/profile&quot;, action=&quot;show&quot;)
    .end()
.end();
&lt;/cfscript&gt;
</code></pre>
