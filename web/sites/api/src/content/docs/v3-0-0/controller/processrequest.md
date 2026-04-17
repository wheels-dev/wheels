---
title: processRequest()
description: "Creates a controller and calls an action on it."
sidebar:
  label: processRequest()
  order: 0
---

## Signature

`processRequest()` — returns `any`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Creates a controller and calls an action on it.
Which controller and action that's called is determined by the params passed in.
Returns the result of the request either as a string or in a struct with <code>body</code>, <code>emails</code>, <code>files</code>, <code>flash</code>, <code>redirect</code>, <code>status</code>, and <code>type</code>.
Primarily used for testing purposes.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `params` | `struct` | yes | — | The params struct to use in the request (make sure that at least `controller` and `action` are set). |
| `method` | `string` | no | `get` | The HTTP method to use in the request (`get`, `post` etc). |
| `returnAs` | `string` | no | — | Pass in `struct` to return all information about the request instead of just the final output (`body`). |
| `rollback` | `string` | no | `false` | Pass in `true` to roll back all database transactions made during the request. |
| `includeFilters` | `string` | no | `true` | Set to `before` to only execute "before" filters, `after` to only execute "after" filters or `false` to skip all filters. |

## Examples

<pre><code class='javascript'>1. Simple request, returns rendered output as string
result = processRequest(params={controller=&quot;users&quot;, action=&quot;show&quot;, id=5});
// Returns: rendered HTML for the users/show action

2. Simulate a POST request
result = processRequest(
    params={controller=&quot;users&quot;, action=&quot;create&quot;, name=&quot;Alice&quot;},
    method=&quot;post&quot;
);
// Returns: rendered output of the create action

3. Get a detailed struct response instead of just body
result = processRequest(
    params={controller=&quot;sessions&quot;, action=&quot;create&quot;, email=&quot;test@example.com&quot;},
    method=&quot;post&quot;,
    returnAs=&quot;struct&quot;
);
// Returns struct with keys: body, emails, files, flash, redirect, status, type

4. Automatically roll back database changes
result = processRequest(
    params={controller=&quot;orders&quot;, action=&quot;create&quot;, product_id=42},
    method=&quot;post&quot;,
    rollback=true
);
// Data is inserted during the request but rolled back afterward

5. Skip all filters
result = processRequest(
    params={controller=&quot;users&quot;, action=&quot;delete&quot;, id=10},
    includeFilters=false
);
// Runs delete action without before/after filters

6. Run only &quot;before&quot; filters (useful for testing filter logic)
result = processRequest(
    params={controller=&quot;users&quot;, action=&quot;edit&quot;, id=10},
    includeFilters=&quot;before&quot;
);
</code></pre>
