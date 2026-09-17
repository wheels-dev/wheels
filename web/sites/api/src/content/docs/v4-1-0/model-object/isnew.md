---
title: isNew()
description: "Returns <code>true</code> if this object hasn't been saved yet (in other words, no matching record exists in the database yet)."
sidebar:
  label: isNew()
  order: 0
---

## Signature

`isNew()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns <code>true</code> if this object hasn't been saved yet (in other words, no matching record exists in the database yet).
Returns <code>false</code> if a record exists.




## Examples

<pre><code class='javascript'>// 1. Check if a newly instantiated object has been saved to the database
employee = model(&quot;Employee&quot;).new(firstName=&quot;Jane&quot;, lastName=&quot;Doe&quot;);
if (employee.isNew()) {
    // employee.save() has not been called yet, so no DB record exists
    employee.save();
}

// 2. Check after loading from the database (isNew() returns false for persisted records)
employee = model(&quot;Employee&quot;).findOne(where=&quot;firstName='Jane'&quot;);
if (!employee.isNew()) {
    // record already exists in the database
    employee.firstName = &quot;Janet&quot;;
    employee.save();
}

// 3. Useful inside a before/after callback to branch logic for new vs. existing records
// In Employee.cfc:
component extends=&quot;Model&quot; {
    function config() {
        beforeSave(&quot;stampAuditFields&quot;);
    }
    private function stampAuditFields() {
        if (isNew()) {
            this.createdBy = request.currentUserId;
        }
        this.updatedBy = request.currentUserId;
    }
}
</code></pre>
