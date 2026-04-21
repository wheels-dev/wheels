---
title: getAvailableMigrations()
description: "Searches db/migrate folder for migrations. Whilst you can use this in your application, the recommended useage is via either the CLI or the provided GUI interfa"
sidebar:
  label: getAvailableMigrations()
  order: 0
---

## Signature

`getAvailableMigrations()` — returns `array`

**Available in:** `migrator`
**Category:** General Functions

## Description

Searches db/migrate folder for migrations. Whilst you can use this in your application, the recommended useage is via either the CLI or the provided GUI interface



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `path` | `string` | no | `[runtime expression]` | Path to Migration Files: defaults to /migrator/migrations/ |

</div>

## Examples

<pre><code class='javascript'>// Get array of available migrations
migrations = application.wheels.migrator.getAvailableMigrations();

if(ArrayLen(migrations)){
	 latestVersion = migrations[ArrayLen(migrations)].version;
} else {
	 latestVersion = 0;
}
</code></pre>
