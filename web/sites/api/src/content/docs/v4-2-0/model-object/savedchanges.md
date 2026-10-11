---
title: savedChanges()
description: "Returns a struct detailing the changes the last successful save wrote to the database, in the"
sidebar:
  label: savedChanges()
  order: 0
---

## Signature

`savedChanges()` — returns `struct`

**Available in:** `model`
**Category:** Change Functions

## Description

Returns a struct detailing the changes the last successful save wrote to the database, in the
same shape as <code>allChanges()</code>: <code>{property: {changedFrom, changedTo}}</code>. Available from the
save's <code>afterCreate</code> / <code>afterUpdate</code> / <code>afterSave</code> callbacks on, after <code>allChanges()</code> has been
reset. Each <code>afterCommit</code> sees the save that queued it, and an <code>afterRollback</code> the save that was
undone. Empty before the first save, after a save that changed nothing, and after <code>reload()</code>.




