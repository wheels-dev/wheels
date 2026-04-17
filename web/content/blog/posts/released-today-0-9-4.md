---
title: 'Released Today: ColdFusion on Wheels 0.9.4'
slug: released-today-0-9-4
publishedAt: '2009-12-15T10:46:59.000Z'
updatedAt: '2025-05-19T22:32:18.000Z'
author: Chris Peters
tags: []
categories:
  - Community
excerpt: >-
  We've just released ColdFusion on Wheels version 0.9.4 today on
  CFWheels.org(https://cfwheels.org/). Thanks to Per Djurner, Tony Petruzzi, and
  James Gibson for contributing new features and improvi...
coverImage: null
legacyId: '30'
---
We've just released ColdFusion on Wheels version 0.9.4 today on [CFWheels.org](https://cfwheels.org/). Thanks to Per Djurner, Tony Petruzzi, and James Gibson for contributing new features and improving the stability of the framework. And thanks to the community for feedback and supporting our efforts. Our presence is really starting to grow.

## Improvements

-   There is a new labelPlacement argument on all form helpers that gives you more control over the label tag.
-   The error email now includes more information and also uses the global defaults you have set on sendEmail().
-   When linking you can now leave out the controller and action arguments and the link will point to the current page.
-   The rendering functions now accept a returnAs argument that you can set to "string" when you want to return the result for more processing instead of just displaying it right away.
-   … and more minor changes and bug fixes.

## New Functionality

-   All finder methods (findByKey(), findAll(), etc.) can now return either an object, multiple objects in an array, or a query result set. You can decide what you want back by setting the returnAs argument to "object", "objects" or "query". The convention is still to return an object when dealing with single records and queries when dealing with multiples.
-   You can now specify a [calculated property](http://www.cfwheels.org/docs/chapter/calculated-properties) (maps to a SQL statement instead of directly to a table column) on a model that you can then reference in finders (selecting, ordering by it, etc).
-   The includePartial() function can now handle an array of objects (similar to the way it can iterate over a query).
-   You can pass in a field name in the group argument of includePartial(), and it will call the partial once for each group and pass in a sub query.
-   When specifying a hasMany association, you can now inform Wheels to create a shortcut to an additional model through a join table (very useful when dealing with many to many relationships).
-   You can now edit multiple objects of the same class in the same form, Wheels will automatically create nested structs in the params struct on the receiving end.

## Documentation Improvements

Along with this release, I'm personally excited to announce that all of the chapter listings are hyperlinked in the [Documentation](https://cfwheels.org/docs) section. Here's what's new:

-   [Calculated Properties](http://www.cfwheels.org/docs/chapter/calculated-properties)
-   [Form Helpers and Showing Errors](http://www.cfwheels.org/docs/chapter/form-helpers-and-showing-errors)
-   [Creating Your Own View Helpers](http://www.cfwheels.org/docs/chapter/creating-your-own-view-helpers)
-   [Miscellaneous Helpers](http://www.cfwheels.org/docs/chapter/miscellaneous-helpers)

We also added information to and improved the following chapters:

-   [Object Validation](http://www.cfwheels.org/docs/chapter/object-validation)
-   [Object Callbacks](http://www.cfwheels.org/docs/chapter/object-callbacks)
-   [Object Relational Mapping](http://www.cfwheels.org/docs/chapter/object-relational-mapping)
-   [Associations](http://www.cfwheels.org/docs/chapter/associations)
-   [Reading Records](http://www.cfwheels.org/docs/chapter/reading-records)
-   [Partials](http://www.cfwheels.org/docs/chapter/partials)

Now is the time to try out ColdFusion on Wheels if you've been on the fence. We're pretty much locked on features until we release 1.0 in a couple months.
