---
title: Building search forms with tableless models in CFWheels
slug: building-search-forms-with-tableless-models-in-cfwheels
publishedAt: '2023-11-12T19:42:55.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Chris Peters
tags:
  - models
categories:
  - Community
  - Documentation
  - Inspiration
  - Tips &amp; Tricks
  - Tutorials
excerpt: >-
  This blog article was originally posted on Chris' personal blog and is
  republished here with his permission.
coverImage: null
legacyId: '128'
---

> This blog article was originally posted on Chris' personal blog and is republished here with his permission.

In this post, I hope to persuade you that you will rarely ever need the `Tag`\-based form helpers (`textFieldTag`, `selectTag`, etc.) in your CFWheels apps ever again.

“How?” you ask.

The answer: through the use of a wonderful feature that we affectionately call [tableless models](http://docs.cfwheels.org/docs/object-relational-mapping#models-without-database-tables).

## How you’re probably used to coding search forms in CFWheels

So let’s code up an index form using the `Tag`\-based helpers that you’re probably accustomed to using in this situation. The view’s job is to display a list of `invoice` records along with a form for narrowing by start date and end date:

```
<cfoutput>

#startFormTag(route="invoices", method="get")#
  #textFieldTag(name="startDate", value=params.startDate)#
  #textFieldTag(name="endDate", value=params.endDate)#
  #submitTag(value="Filter Invoices")#
#endFormTag()#

<table>
  <thead>
    <tr>
      <th>Invoice</th>
      <th>Date</th>
      <th>Amount</th>
    </tr>
  </thead>
  <tbody>
    <cfloop query="invoices">
      <tr>
        <td>#h(id)#</td>
        <td>#DateFormat(createdAt)#</td>
        <td>#DollarFormat(amount)#</td>
      </tr>
    </cfloop>
  </tbody>
</table>

</cfoutput>
```

This is pretty common, and I wouldn’t go as far to say that it’s wrong.

Let’s code what we need in the controller to wire everything up.

```
component extends="Controller" {
  function index() {
    param name="params.startDate" default="";
    param name="params.endDate" default="";

    local.where = [];

    if (IsDate(params.startDate)) {
      ArrayAppend(local.where, "createdAt >= '#params.startDate#'");
    }

    if (IsDate(params.endDate)) {
      local.nextDay = DateAdd("d", 1, params.endDate);
      local.nextDay = DateFormat(local.nextDay, "m/d/yyyy");
      ArrayAppend(local.where, "createdAt < '#local.nextDay#'");
    }

    invoices = model("invoice").findAll(where=ArrayToList(local.where, " AND "));
  }
}
```

But wait! We can’t have a `startDate` that occurs after the `endDate`. We better add a check for that in the controller:

```
component extends="Controller" {
  function index() {
    param name="params.startDate" default="";
    param name="params.endDate" default="";

    local.where = [];

    // Let's make sure the start date and end date jive.
    if (IsDate(params.startDate) && IsDate(params.endDate) && params.startDate > params.endDate) {
      flashInsert(error="The start date must be on or before the end date.");
    }

    if (IsDate(params.startDate)) {
      ArrayAppend(local.where, "createdAt >= '#params.startDate#'");
    }

    if (IsDate(params.endDate)) {
      local.nextDay = DateAdd("d", 1, params.endDate);
      local.nextDay = DateFormat(local.nextDay, "m/d/yyyy");
      ArrayAppend(local.where, "createdAt < '#local.nextDay#'");
    }

    invoices = model("invoice").findAll(where=ArrayToList(local.where, " AND "));
  }
}
```

That `index` action is getting pretty beefy at this point. And now we’re starting to validate our data in the controller, which can quickly turn into a tangled mess after we’ve added another field or two to the form.

## Cleaning up the search form with tableless models

As it turns out, models in CFWheels come with a bunch of really helpful methods for validating data. And even though we’re not using this form to save data to a database, we can still use the model validations to validate our data. Hooray!

All that we need to do is create a CFC in our `models` folder that represents this particular form. The initializer will contain a call to `table(false)`, which tells CFWheels to not try to connect it to a database.

In addition to `table(false)`, we can call all of the model validation initializers that we need to validate the data.

Lastly, we need to create a method that validates data passed into the model and runs the query if all is well.

Here is the finished product in `models/InvoiceSearchForm.cfc`:

```
component extends="Model" {
  function config() {
    // Make it tableless
    table(false);

    // Validations
    validatesFormatOf(properties="startDate,endDate", type="date", allowBlank=true);
    validate("startDateBeforeEndDateValidation");
  }

  boolean function run() {
    // Run validations and abort if failed.
    if (!this.valid()) {
      this.results = QueryNew("");
      return false;
    }

    // Continue with query if validation passed.
    local.where = [];

    if (IsDate(this.startDate)) {
      ArrayAppend(local.where, "createdAt >= '#this.startDate#'");
    }

    if (IsDate(this.endDate)) {
      local.nextDay = DateAdd("d", 1, this.endDate);
      local.nextDay = DateFormat(local.nextDay, "m/d/yyyy");
      ArrayAppend(local.where, "createdAt < '#local.nextDay#'");
    }

    this.results = model("invoice").findAll(where=ArrayToList(local.where, " AND "));
    return true;
  }

  private function startDateBeforeEndDateValidation() {
    if (IsDate(this.startDate) && IsDate(this.endDate) && this.startDate > this.endDate) {
      this.addError("startDate", "Start Date must be on or before End Date");
    }
  }
}
```

Notice that `startDate` and `endDate` become properties on the model in the `this` scope. This allows us to validate those properties and refer to them in an object-oriented manner.

When the `run` method is called, there will be a `results` property set on the object containing the search query.

Next, we rewire the controller to this much simpler form:

```
component extends="Controller" {
  function index() {
    // Note that moving this into an object named `search` will change the
    // `params` struct slightly.
    param name="params.search.startDate" default="";
    param name="params.search.endDate" default="";

    // We pass the `params.search` struct in as properties on the search form
    // object.
    search = model("invoiceSearchForm").new(argumentCollection=params.search);

    // This runs the search and adds an error message if validation fails.
    if (!search.run()) {
      flashInsert(error="There was an error with your search filters");
    }
  }
}
```

Much cleaner, huh? Excluding whitespace and comments, this reduces the contents of the `index` action from 16 lines of actual code to 5.

This methodology also improves the view because we can now use `textField` instead of `textFieldTag`, and we can display validation errors near the affected form fields:

```
<cfoutput>

#startFormTag(route="invoices", method="get")#
  #textField(objectName="search", property="startDate")#
  #errorMessageOn(objectName="search", property="startDate")#

  #textField(objectName="search", property="endDate")#
  #errorMessageOn(objectName="search", property="endDate")#

  #submitTag(value="Filter Invoices")#
#endFormTag()#

<table>
  <thead>
    <tr>
      <th>Invoice</th>
      <th>Date</th>
      <th>Amount</th>
    </tr>
  </thead>
  <tbody>
    <cfloop query="search.results">
      <tr>
        <td>#h(id)#</td>
        <td>#DateFormat(createdAt)#</td>
        <td>#DollarFormat(amount)#</td>
      </tr>
    </cfloop>
  </tbody>
</table>

</cfoutput>
```

As a bonus, our `InvoiceSearchForm` model allows us to do things like set the labels/error message labels on the form fields using `property`, and allows us to do most of what models allow us to do: namely validations and callbacks.

```
component extends="Model" {
  function config() {
    table(false);

    // Set property labels for form fields and related error messages.
    property(name="startDate", label="Start");
    property(name="endDate", label="End");

    //...
  }

  //...
}
```

I find this to be a nice pattern because it ties the form to the model in a fairly clean, object-oriented way: the model represents the form, so it makes sense for it to define how labels on the form should appear.

## Other uses for tableless models

Here are some other ideas where tableless models are a Good Idea™:

**Authentication forms**  
The model takes care of all authentication logic.

**Password change/reset forms**  
Move interface-based concepts like `validatesConfirmationOf` out of the table-based `user` model and into a tableless model.

**Database transactions involving multiple models**  
Nested properties have their limits and logic related to them can really pollute your table-based models. Handle all of the logic in a model that’s intimately involved with the form.

**Reports**  
Have you ever found yourself in a situation where you needed to run a query involving multiple database tables, but it was unclear which model to write the query in? Tableless models are a perfect way to avoid making a random decision.

**NoSQL and API integration**  
Are you saving your data somewhere other than a relational database? You can still model the business logic using CFWheels models.

## Props

Most of this inspiration came from a similar concept known as [Form Objects](https://robots.thoughtbot.com/activemodel-form-objects) in Ruby on Rails. (There is a great [Railscast about Form Objects](http://railscasts.com/episodes/416-form-objects)here too.)

Also, major kudos to Tony Petruzzi for adding this awesome feature into CFWheels, which made its way into the v1.3 release.
