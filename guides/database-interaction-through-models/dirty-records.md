---
description: How to track changes to objects in your application.
---

# Dirty Records

Wheels provides some very useful methods for tracking changes to objects. You might think, _Why do I need that? Won't I just know that I changed the object myself?_

Well, that depends on the structure of your code.

As you work with Wheels and move away from that procedural spaghetti mess you used to call code to a better, cleaner object-oriented approach, you may get a sense that you have lost control of what your code is doing. Your new code is creating objects, they in turn call methods on other objects automatically, methods are being called from multiple places, and so on. Don't worry though, this is a good thing. It just takes a while to get used to, and with the help of some Wheels functionality, it won't take you that long to get used to it either.

### An Example with Callbacks

One area where this sense of losing control is especially noticeable is when you are using _callbacks_ on objects (see the chapter on [Object Callbacks](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/database-interaction-through-models/object-callbacks) for more info). So let's use that for our example.

Let's say you have used a callback to specify that a method should be called whenever a `user` object is saved to the database. You won't know exactly **where** this method was called from. It could have been the user doing it themselves on the website, or it could have been done from your internal administration area. Generally speaking, you don't need to know this either.

One thing your business logic might need to know though is a way to tell exactly **what** was changed on the object. Maybe you want to handle things differently if the user's last name was changed than if the email address was changed, for example.

Let's look at the methods Wheels provide to make tracking these changes easier for you.

### Methods for Tracking Changes

Let's get to coding…

```javascript
post = model("post").findByKey(1);
result = post.hasChanged();
```

Here we are using the [hasChanged()](https://wheels.dev/api/v3.0.0/model.haschanged.html) method to see if any of the object properties has changed.

By the way, when we are talking about "change" in Wheels, we always mean whether or not an object's properties have changed compared to what is stored in the columns they map to in the database table.

In the case of the above example, the `result` variable will contain `false` because we just fetched the object from the database and did not make any changes to it at all.

Well, let's make a change then. If we didn't, this chapter wouldn't be all that interesting, would it?

```javascript
post.title = "A New Post Title";
result = post.hasChanged();
```

Now result will be `true` because what is stored in `post.title` differs from what is stored in the `title`column for this record in the `posts` table (well, unless the title was "A New Post Title" even before the change, in which case the result would still be `false`).

When calling [hasChanged()](https://wheels.dev/api/v3.0.0/model.haschanged.html) with no arguments, Wheels will check **all** properties on the object and return `true` if any of them have changed. If you want to see if a specific property has changed, you can pass in `property="title"` to it or use the dynamic method `[propertyName]HasChanged()`. Replace `[propertyName]` with the name of the property. In our case, the method would then be named `titleHasChanged()`.

If you want to see what a value was before a change was made, you can do so by calling [changedFrom()](https://wheels.dev/api/v3.0.0/model.changedfrom.html) and passing in the name of a property. This can also be done with the dynamic `[propertyName]ChangedFrom()` method.

When an object is in a changed state, there are a couple of methods you can use to report back on these changes. [changedProperties()](https://wheels.dev/api/v3.0.0/model.changedproperties.html) will give you a list of the property names that have been changed. [allChanges()](https://wheels.dev/api/v3.0.0/model.allchanges.html) returns a struct containing all the changes (both the property names and the changed values themselves).

If you have made changes to an object and for some reason you want to revert it back, you can do so by calling [reload()](https://wheels.dev/api/v3.0.0/model.reload.html) on it. This will query the database and update the object properties with their corresponding values from the database.

OK, let's save the object to the database now and see how that affects things.

```javascript
post.save();
result = post.hasChanged();
```

Now `result` will once again contain `false`. When you save a changed (a.k.a. "dirty") object, it clears out its changed state tracking and is considered unchanged again.

### Don't Forget the Context

All of the examples in this chapter look a little ridiculous because it doesn't make much sense to check the status of an object when you changed it manually in your code. As we said in the beginning of the chapter, when put into context of callbacks, multiple methods, etc., it will become clear how useful these methods really are.

### Internal Use of Change Tracking

It's worth noting here that Wheels makes good use of this change tracking internally as well. If you make changes to an object, Wheels is smart enough to only update the changed columns, leaving the rest alone. This is good for a number of reasons but perhaps most importantly for database performance. In high traffic web applications, the bottleneck is often the database, and anything that can be done to prevent unnecessary database access is a good thing.

### One "Gotcha" About Tracking Changes

If you create a brand new object with the [new()](https://wheels.dev/api/v3.0.0/model.new.html) method and call [hasChanged()](https://wheels.dev/api/v3.0.0/model.haschanged.html) on it, it will return `true`. The reason for this seemingly unexpected behavior is that change is always viewed from the database's perspective. The [hasChanged()](https://wheels.dev/api/v3.0.0/model.haschanged.html) method will return `true` in this case because it is different from what is stored in the database (i.e. it doesn't exist at all in the database yet).

If you would simply like to know if an object exists in the database or not, you can use the [isNew()](https://wheels.dev/api/v3.0.0/model.isnew.html) method.
