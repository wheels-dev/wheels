---
description: How to use more than one database in your Wheels application.
---

# Using Multiple Data Sources

Sometimes you need to pull data from more than one database, whether it's by choice (for performance or security reasons, perhaps) or because that's the way your infrastructure is set up. It's something you have to find a way to deal with.

Wheels has built-in functionality for this so that you don't have to revert back to writing the queries and setting the data source manually whenever you need to use a data source other than the default one. In order accomplish this, you will use the [dataSource()](https://wheels.dev/api/v3.0.0/model.datasource.html) function.

### Using the dataSource() Function

Overriding the default data source is done on a per model basis in Wheels by calling the [dataSource()](https://wheels.dev/api/v3.0.0/model.datasource.html)function from within your model's `config()` method. By doing this, you instruct wheels to use that data source whenever it interacts with that model.

Here's an example of a model file:

```javascript
component extends="Model" {

  function config(){
    dataSource("mySecondDatabase");
  }

}
```

It's important to note that in order for Wheels to use the data source, it must first be configured in your respective CFML engine (i.e. in the Adobe ColdFusion, Lucee Admin etc).

### Does Not Work with Associations

One thing to keep in mind when using multiple data sources with Wheels is that it doesn't work across associations. When including another model within a query, Wheels will use the calling model's data source for the context of the query.

Let's say you have the following models set up:

{% code title="app/models/Photo.cfc" %}
```javascript
component extends="Model" {

  function config(){
    dataSource("myFirstDatabase");
    hasMany("photoGalleries");
  }

}
```
{% endcode %}

{% code title="app/models/PhotoGallery.cfc" %}
```javascript
component extends="Model" {

  function config(){
    dataSource("mySecondDatabase");
  }

}
```
{% endcode %}

Because the `photo` model is the main model being used in the following example, its data source (`myFirstDatabase`) will be the one used in the query that [findAll()](https://wheels.dev/api/v3.0.0/model.findall.html) ends up executing.

{% code title="FindAll Call" %}
```javascript
myPhotos = model("photo").findAll(include="photoGalleries");
```
{% endcode %}
