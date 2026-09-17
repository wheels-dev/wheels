---
title: tenant()
description: "Returns the current tenant struct, or an empty struct if no tenant is active."
sidebar:
  label: tenant()
  order: 0
---

## Signature

`tenant()` — returns `struct`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Multi-Tenancy

## Description

Returns the current tenant struct, or an empty struct if no tenant is active.
The tenant struct contains: <code>id</code>, <code>dataSource</code>, <code>config</code>, and <code>$locked</code>.
A tenant only counts as active when it carries a non-empty <code>dataSource</code> — the same test
<code>$tenantDataSource()</code> applies before it routes a query. Anything else on the key reads as
no tenant rather than being handed back as though it were a resolved one, so a malformed
value degrades to a no-op instead of wrong behaviour (#3336). Every framework producer
(<code>switchTenant()</code>, <code>TenantResolver</code>, <code>Job.$restoreTenantContext()</code>, <code>TenantMigrator</code>)
already guarantees a non-empty <code>dataSource</code>, so this only filters foreign values.




## Examples

<pre><code class='javascript'>// 1. Get the active tenant struct (when a tenant is set)
t = tenant();
// t -&gt; {id: &quot;acme&quot;, dataSource: &quot;tenant_db_acme&quot;, config: {}, $locked: true}

// 2. Check whether a tenant is active before using its properties
t = tenant();
if (!structIsEmpty(t)) {
    writeOutput(&quot;Current tenant: &quot; &amp; t.id);
} else {
    writeOutput(&quot;No tenant active — using application defaults.&quot;);
}

// 3. Access a per-tenant config value set via switchTenant()
t = tenant();
if (structKeyExists(t, &quot;config&quot;) &amp;&amp; structKeyExists(t.config, &quot;timeZone&quot;)) {
    writeOutput(&quot;Tenant time zone: &quot; &amp; t.config.timeZone);
}
</code></pre>
