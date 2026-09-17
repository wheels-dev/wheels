---
title: processRequest()
description: "Creates a controller and calls an action on it."
sidebar:
  label: processRequest()
  order: 0
---

## Signature

`processRequest()` — returns `any`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Creates a controller and calls an action on it.
Which controller and action that's called is determined by the params passed in.
Returns the result of the request either as a string or in a struct with <code>body</code>, <code>emails</code>, <code>files</code>, <code>flash</code>, <code>redirect</code>, <code>status</code>, and <code>type</code>.
Primarily used for testing purposes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `params` | `struct` | yes | — | The params struct to use in the request (make sure that at least `controller` and `action` are set). |
| `method` | `string` | no | `get` | The HTTP method to use in the request (`get`, `post` etc). |
| `returnAs` | `string` | no | — | Pass in `struct` to return all information about the request instead of just the final output (`body`). |
| `rollback` | `string` | no | `false` | Pass in `true` to roll back all database transactions made during the request. |
| `includeFilters` | `string` | no | `true` | Set to `before` to only execute "before" filters, `after` to only execute "after" filters or `false` to skip all filters. |
| `csrf` | `string` | no | `ignore` | CSRF handling for this request. Default `ignore` preserves the historic test helper. Pass `exception` or `abort` to enforce; this is opt-in and does not change the production `protectsFromForgery()` default. |

</div>

## Examples

<pre><code class='javascript'>// 1. Basic usage: simulate a GET request to the Users#index action and return the rendered body.
result = processRequest(params={controller=&quot;users&quot;, action=&quot;index&quot;});
// result -&gt; &quot;&lt;html&gt;...&lt;/html&gt;&quot;

// 2. Simulate a POST request to create a new user and return the full response struct.
result = processRequest(
    params={controller=&quot;users&quot;, action=&quot;create&quot;, firstName=&quot;Jane&quot;, lastName=&quot;Doe&quot;},
    method=&quot;post&quot;,
    returnAs=&quot;struct&quot;
);
// result.status   -&gt; 302
// result.redirect -&gt; &quot;/users&quot;
// result.body     -&gt; &quot;&quot;
// result.flash    -&gt; {success=&quot;User created.&quot;}

// 3. Roll back all database changes made during the request (useful in tests to keep data clean).
result = processRequest(
    params={controller=&quot;users&quot;, action=&quot;create&quot;, firstName=&quot;Jane&quot;},
    method=&quot;post&quot;,
    rollback=true,
    returnAs=&quot;struct&quot;
);
// result.status -&gt; 302

// 4. Run the action without any filters (bypass before/after filter logic).
result = processRequest(
    params={controller=&quot;users&quot;, action=&quot;index&quot;},
    includeFilters=false
);
// result -&gt; &quot;&lt;html&gt;...&lt;/html&gt;&quot;
</code></pre>
