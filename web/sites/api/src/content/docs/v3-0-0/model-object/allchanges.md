---
title: allChanges()
description: "Returns a struct containing all unsaved changes made to an object since it was last loaded or saved. Each entry in the struct uses the property name as the key"
sidebar:
  label: allChanges()
  order: 0
---

## Signature

`allChanges()` — returns `struct`

**Available in:** `model`
**Category:** Change Functions

## Description

Returns a struct containing all unsaved changes made to an object since it was last loaded or saved. Each entry in the struct uses the property name as the key and the new (unsaved) value as the value.




## Examples

<pre><code class='javascript'>1. Basic usage
member = model("member").findByKey(params.memberId);

// Change some values (not saved yet)
member.firstName = params.newFirstName;
member.email = params.newEmail;

// Get all pending changes
allChanges = member.allChanges();
// Example output: {"email":{"CHANGEDTO":"old@gmail.com","CHANGEDFROM":"new@gmail.com"},"firstname":{"CHANGEDTO":"old","CHANGEDFROM":"new"}}

2. Checking if changes exist before saving
member = model("member").findByKey(42);
member.status = "inactive";

if (!structIsEmpty(member.allChanges())) {
    writeDump(var=member.allChanges(), label="Pending Changes");
    member.save();
}

3. Using in a validation callback
afterValidation("logChanges");

function logChanges() {
    var changes = this.allChanges();
    if (!structIsEmpty(changes)) {
        log(message="User ##this.id## updated fields: #structKeyList(changes)#");
    }
}

4. Example with multiple updates
user = model("user").findByKey(10);

user.firstName = "Jane";
user.lastName  = "Doe";
user.email     = "jane.doe@example.com";

changes = user.allChanges();
// Output might be: {"email":{"CHANGEDTO":"jane.doe@example.com","CHANGEDFROM":"example.user@gmail.com"},"lastname":{"CHANGEDTO":"Doe","CHANGEDFROM":"user"},"firstname":{"CHANGEDTO":"Jane","CHANGEDFROM":"example"}}</code></pre>
