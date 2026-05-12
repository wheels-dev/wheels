---
title: ColdFusion on Wheels 1.1.4 released
slug: 1-1-4-released
publishedAt: '2011-07-22T23:53:34.000Z'
updatedAt: '2025-05-19T22:32:02.000Z'
author: Chris Peters
tags:
  - 1-1
categories:
  - Releases
excerpt: >-
  Today, we're releasing ColdFusion on Wheels version
  1.1.4(https://cfwheels.org/download). This release fixes numerous bugs and
  adds a nice feature: Now you no longer need to create a zip file to st...
coverImage: null
legacyId: '69'
---

Today, we're releasing [ColdFusion on Wheels version 1.1.4](https://cfwheels.org/download). This release fixes numerous bugs and adds a nice feature: Now you no longer need to create a zip file to start working on a new plugin. You just create a folder for it in the plugins folder and start coding your CFC. To upgrade, you just need to replace the wheels folder in your application with the new wheels folder in the [zip file](https://cfwheels.org/download). The following [changes](https://github.com/cfwheels/cfwheels/blob/v1.1.4/wheels/CHANGELOG 'Version 1.1.4 CHANGELOG') have been made for this release:

### View Enhancements

- Allow an array of structs to used for options in `selectTag()`
- Added `secondStep` parameter to date/time select tags

### Model Enhancements

- Update to `belongsTo()`, `hasOne()` and `hasMany()` for the new argument `joinKey`.
- You can pass an unlimited number properties when using dynamic finders
- Dynamic finders now support passing in an array for values
- Added the `delimiter` argument to dynamic finders, this allow you to change the delimiter
- Added `validationTypeForProperty()` method

### Other Enhancements

- Added proper HTTP status headers
- Plugin development no longer requires a zip file

### Bug Fixes

- Incorrect MIME type for JSON
- Route with format will cause exception when route is selected and format is not provided
- Raise `renderError` when template is not found for format
- `labelClass` should split up the list of classes and attach one class for each label
- Transactions would not close when used with the `dependent` argument of `hasMany()`
- Soft deletes do not work correctly with outer joins
- Better error message when supplying a query param of type string and omitting single quotes
- Allow commas in dynamic finders
- AMPM select displaying twice
- `$request` `argumentsCollection`: should be `argumentCollection`
- Pagination pull incorrect number of results with compounded keys
- Update `hasChanged()` to properly check floats
- Date tags selected date throws out of range error
