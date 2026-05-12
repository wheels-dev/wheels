---
title: Configuration
description: "21 Configuration functions in Wheels 2.1.0."
---

- [`addFormat()`](/v2-1-0/configuration/addformat/) — Adds a new MIME type to your CFWheels application for use with responding to multiple formats.
- [`collection()`](/v2-1-0/configuration/collection/) — A collection route doesn't require an id because it acts on a collection of objects.
- [`constraints()`](/v2-1-0/configuration/constraints/) — Set variable patterns to use for matching.
- [`controller()`](/v2-1-0/configuration/controller/) — Considered deprecated as this doesn't conform to RESTful routing principles; Try not to use this.
- [`delete()`](/v2-1-0/configuration/delete/) — Create a route that matches a URL requiring an HTTP <code>DELETE</code> method. We recommend using this matcher to expos
- [`end()`](/v2-1-0/configuration/end/) — Call this to end a nested routing block or the entire route configuration. This method is chained on a sequence of routi
- [`get()`](/v2-1-0/configuration/get/) — Create a route that matches a URL requiring an HTTP <code>GET</code> method. We recommend only using this matcher to exp
- [`get()`](/v2-1-0/configuration/get/) — Returns the current setting for the supplied CFWheels setting or the current default for the supplied CFWheels function 
- [`mapper()`](/v2-1-0/configuration/mapper/) — Returns the mapper object used to configure your application's routes. Usually you will use this method in <code>config/
- [`member()`](/v2-1-0/configuration/member/) — Scope routes within a nested resource which require use of the primary key as part of the URL pattern;
- [`namespace()`](/v2-1-0/configuration/namespace/) — Scopes any the controllers for any routes configured within this block to a subfolder (package) and also adds the packag
- [`package()`](/v2-1-0/configuration/package/) — Scopes any the controllers for any routes configured within this block to a subfolder (package) without adding the packa
- [`patch()`](/v2-1-0/configuration/patch/) — Create a route that matches a URL requiring an HTTP <code>PATCH</code> method. We recommend using this matcher to expose
- [`post()`](/v2-1-0/configuration/post/) — Create a route that matches a URL requiring an HTTP <code>POST</code> method. We recommend using this matcher to expose 
- [`put()`](/v2-1-0/configuration/put/) — Create a route that matches a URL requiring an HTTP <code>PUT</code> method. We recommend using this matcher to expose a
- [`resource()`](/v2-1-0/configuration/resource/) — Create a group of routes that exposes actions for manipulating a singular resource. A singular resource exposes URL patt
- [`resources()`](/v2-1-0/configuration/resources/) — Create a group of routes that exposes actions for manipulating a collection of resources. A plural resource exposes URL 
- [`root()`](/v2-1-0/configuration/root/) — Create a route that matches the root of its current context. This mapper can be used for the application's web root (or 
- [`scope()`](/v2-1-0/configuration/scope/) — Set any number of parameters to be inherited by mappers called within this matcher's block. For example, set a package o
- [`set()`](/v2-1-0/configuration/set/) — Use to configure a global setting or set a default for a function.
- [`wildcard()`](/v2-1-0/configuration/wildcard/) — Special wildcard matching generates routes with `
