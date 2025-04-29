---
description: >-
  Learn the goals of Wheels as well as web development frameworks in general.
  Then learn more about some key concepts in Wheels.
---

# Frameworks and Wheels

This chapter will introduce you to frameworks in general and later specifically to Wheels. We'll help you decide if you even need a framework at all and what common problems a framework tries to solve. If we're able to convince you that using a framework is the right thing for you, then we'll present our goals with creating Wheels and show you some key Wheels concepts.

So let's get started.&#x20;

### Do I Really Need to Use a Framework?

Short answer, no. If you don't mind doing the same thing over and over again and are getting paid by the hour to do so, then by all means keep doing that.

Slightly longer answer, no. If you're working on a highly customized project that does not fall within what 9 out of 10 web sites/applications normally do then you likely need a high percentage of custom code, and a framework will not help much.

However, if you're like most of us and have noticed that for every new project you start on--or even every new feature you add to an existing project--you waste a lot of time re-creating the wheel, then you should read on because Wheels may just be the solution for you!

Wheels will make starting a new project or building a new feature quick and painless. You can get straight to solving business problems on day one! To understand how this is achieved, we figured that a little background info on frameworks in general may help you out.

All good frameworks rise from the need to solve real problems in real world situations. Wheels is based heavily on the Rails framework for Ruby and also gets inspiration from Django and, though to a lesser extent, other frameworks in the ColdFusion space (like Fusebox, for example). Over the years the contributors to these frameworks have identified problems and tedious tasks in their own development processes, built a solution for it, and abstracted (made it more generic so it suits any project) the solution into the framework in question. Piggy-backing on what all these great programmers have already created and adding a few nice solutions of our own, Wheels stands on solid ground.

OK, so that was the high level overview of what frameworks are meant to do. But let's get a little more specific.

### Framework Goals in General

Most web development frameworks set out to address some or all of these common concerns:

* Map incoming requests to the code that handles them.
* Separate your business logic from your presentation code.
* Let you work at a higher level of abstraction, thus making you work faster.
* Give you a good code organization structure to follow.
* Encourage clean and pragmatic design.
* Simplify saving data to a storage layer.

Like all other good frameworks, Wheels does all this. But there are some subtle differences, and certain things are more important in Wheels than in other frameworks and vice versa. Let's have a look at the specific goals with Wheels so you can see how it relates to the overall goals of frameworks in general.

### Our Goals With Wheels

As we've said before, Wheels is heavily based on Ruby on Rails, but it's not a direct port, and there are some things that have been changed to better fit the CFML language. Here's a brief overview of the goals we're striving for with Wheels (most of these will be covered in greater detail in later chapters):

#### Simplicity

We strive for simplicity on a lot of different levels in Wheels. We'll gladly trade code beauty in the framework's internal code for simplicity for the developers who will use it. This goal to keep things simple is evident in a lot of different areas in Wheels. Here are some of the most notable ones:

* The concept of object oriented programming is very simple and data-centric in Wheels, rather than 100% "pure" at all times.
* By default, you'll always get a query result set back when dealing with multiple records in Wheels, simply because that is the way we're all used to outputting data.
* Wheels encourages best practices, but it will never give you an error if you go against any of them.
* With Wheels, you won't program yourself into a corner. If worse comes to worse, you can always drop right out of the framework and go back to old school code for a while if necessary.
* Good old CFML code is used for everything, so there is no need to mess with XML for example.

What this means is that you don't have to be a fantastic programmer to use the framework (although it doesn't hurt). It's enough if you're an average programmer. After using Wheels for a while, you'll probably find that you've become a better programmer though!

#### Documentation

If you've ever downloaded a piece of open source software, then you know that most projects lack documentation. Wheels hopes to change that. We're hoping that by putting together complete, up-to-date documentation that this framework will appeal, and be usable, by everyone. Even someone who has little ColdFusion programming background, let alone experience with frameworks.

### Key Wheels Concepts

Besides what is already mentioned above, there are some key concepts in Wheels that makes sense to familiarize yourself with early on. If you don't feel that these concepts are to your liking, feel free to look for a different framework or stick to using no framework at all. Too often programmers choose a framework and spend weeks trying to bend it to do what they want to do rather than follow the framework conventions.

Speaking of conventions, this brings us to the first key concept:

#### Convention Over Configuration

Instead of having to set up tons of configuration variables, Wheels will just assume you want to do things a certain way by using default settings. In fact, you can start programming a Wheels application without setting any configuration variables at all!

If you find yourself constantly fighting the conventions, then that is a hint that you're not yet ready for Wheels or Wheels is not ready for you.

#### Beautiful Code

Beautiful (for lack of a better word) code is code that you can scan through and immediately see what it's meant to do. It's code that is never repeated anywhere else. And, most of all, it's code that you'll enjoy writing and will enjoy coming back to 6 months from now.

Sometimes the Wheels structure itself encourages beautiful code (separating business logic from request handling, for example). Sometimes it's just something that comes naturally after reading documentation, viewing other Wheels applications, and talking to other Wheels developers.

#### Model-View-Controller (MVC)

If you've investigated frameworks in the past, then you've probably heard this terminology before. Model-View-Controller, or MVC, is a way to structure your code so that it is broken down into three easy-to-manage pieces:

* **Model:** Just another name for the representation of data, usually a database table.
* **View:** What the user or their browser sees and interacts with (a web page in most cases).
* **Controller:** The behind-the-scenes guy that's coordinating everything.

"Uh, yeah. So what's this got to do with anything?" you may ask. MVC is how Wheels structures your code for you. As you start working with Wheels applications, you'll see that most of the code you write (database queries, forms, and data manipulation) are very nicely separated into one of these three categories.

The benefits of MVC are limitless, but one of the major ones is that you almost always know right where to go when something needs to change.

If you've added a column to the vehicles table in your database and need to give the user the ability to edit that field, all you need to change is your View. That's where the form is presented to the user for editing.

If you find yourself constantly getting a list of all the red cars in your inventory, you can add a new method to your model called `getRedCars()` that does all the work for you. Then when you want that list, just add a call to that method in your controller and you've got 'em!

#### Object Relational Mapping (ORM)

The Object Relational Mapping, or ORM, in Wheels is perhaps the one thing that could potentially speed up your development the most. An ORM handles mapping objects in memory to how they are stored in the database. It can replace a lot of your query writing with simple methods such as `user.save()`, `blogPost.comments(order="date")`, and so on. We'll talk a lot more about the ORM in Wheels in the chapters about models.

### There's Your Explanation

So there you have it, a completely fair and unbiased introduction to Wheels. ;)

If you've been developing ColdFusion applications for a while, then we know this all seems hard to believe. But trust us; it works. And if you're new to ColdFusion or even web development in general, then you probably aren't aware of most of the pains that Wheels was meant to alleviate!

That's okay. You're welcome in the Wheels camp just the same.
