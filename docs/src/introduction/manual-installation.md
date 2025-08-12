---
description: Instructions for installing Wheels on your system.
---

# Manual Installation

Installing Wheels is so simple that there is barely a need for a chapter devoted to it. But we figured we'd better make one anyway in case anyone is specifically looking for a chapter about installation.

So, here are the simple steps you need to follow to get rolling on Wheels...

### Manual Installation

### 1. Download Wheels

You have 2 choices when downloading Wheels. You can either use the latest official release of Wheels, or you can take a walk on the wild side and go with the latest committed source code in our Git repository.

The latest official releases can always be found in the [Releases](https://github.com/wheels-dev/wheels/releases) section of GitHub, and the Git repository is available at our [GitHub repo](https://github.com/wheels-dev/wheels).

In most cases, we recommend going with the official release because it's well documented and has been through a lot of bug testing. Only if you're in desperate need of a feature that has not been released yet would we advise you to go with the version stored in the Git `master` branch.

Let's assume you have downloaded the latest official release. (Really, you should go with this option.) You now have a `.zip` file saved somewhere on your computer. On to the next step...

### 2. Setup the Website

Getting an empty website running with Wheels installed is an easy process if you already know your way around IIS or Apache. Basically, you need to create a new website in your web server of choice and unzip the contents of the file into the root of it.

In case you're not sure, here are the instructions for setting up an empty Wheels site that can be accessed when typing `localhost` in your browser. The instructions refer to a system running Windows Server 2003 and IIS, but you should be able to follow along and apply the instructions with minor modifications to your system. (See [Requirements](http://wheels.dev/3.0.0/guides/introduction/requirements) for a list of tested systems).

* Create a new folder under your web root (usually `C:\Inetpub\wwwroot`) named `wheels_site` and unzip the Wheels `.zip` file into the root of it.
* Create a new website using IIS called `Wheels Site` with `localhost` as the host header name and `C:\Inetpub\wwwroot\mysite` as the path to your home directory.

If you want to run a Wheels-powered application from a subfolder in an existing website, this is entirely possible, but you may need to get a little creative with your URL rewrite rules if you want to get pretty URLs--it will only work out of the box on recent versions of Apache. (Read more about this in the [URL Rewriting](https://wheels.dev/3.0.0/guides/handling-requests-with-controllers/url-rewriting/README) chapter.)

### 3. Setup the Database (Optional)

Create a new database in MySQL, PostgreSQL, Microsoft SQL Server, Oracle or H2 and add a new data source for it in the ColdFusion/Lucee Administrator, just as you'd normally do. Now open up `/config/settings.cfm` and call `set(dataSourceName="")` with the name you chose for the data source.

If you don't want to be bothered by opening up a Wheels configuration file at all, there is a nice convention you can follow for the naming. Just name your data source with the same name as the folder you are running your website from (`mysite` in the example above), and Wheels will use that when you haven't set the `dataSourceName` setting using the [Set()](https://wheels.dev/api/v3.0.0/v3.0.0-SNAPSHOT/set.html) function.

### 4. Test It

When you've followed the steps above, you can test your installation by typing `http://localhost/` (or whatever you set as the host header name) in your web browser. You should get a "Congratulations!" page.

That's it. You're done. This is where the fun begins!
