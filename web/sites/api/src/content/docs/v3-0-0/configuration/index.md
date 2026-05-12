---
title: Configuration
description: "21 Configuration functions in Wheels 3.0.0."
---

- [`addFormat()`](/v3-0-0/configuration/addformat/) — Registers a new MIME type in your Wheels application for use with responding to multiple formats. This is helpful when y
- [`collection()`](/v3-0-0/configuration/collection/) — Defines a collection route in your Wheels application. Collection routes operate on a set of resources and do not requir
- [`constraints()`](/v3-0-0/configuration/constraints/) — Defines variable patterns for route parameters when setting up routes using the Wheels mapper(). This allows you to rest
- [`controller()`](/v3-0-0/configuration/controller/) — The controller() function in Wheels is used to define routes that point to a specific controller. However, it is conside
- [`delete()`](/v3-0-0/configuration/delete/) — Create a route that matches a URL requiring an HTTP <code>DELETE</code> method. We recommend using this matcher to expos
- [`end()`](/v3-0-0/configuration/end/) — Call this to end a nested routing block or the entire route configuration. This method is chained on a sequence of routi
- [`get()`](/v3-0-0/configuration/get/) — Create a route that matches a URL requiring an HTTP <code>GET</code> method. We recommend only using this matcher to exp
- [`get()`](/v3-0-0/configuration/get/) — Returns the current value of a Wheels configuration setting or the default value for a specific function argument. It ca
- [`mapper()`](/v3-0-0/configuration/mapper/) — Returns the mapper object used to configure your application's routes. Usually you will use this method in <code>app/con
- [`member()`](/v3-0-0/configuration/member/) — Scope routes within a nested resource which require use of the primary key as part of the URL pattern;
- [`namespace()`](/v3-0-0/configuration/namespace/) — The namespace() function in Wheels is used to group controllers and routes under a specific namespace (subfolder/package
- [`package()`](/v3-0-0/configuration/package/) — Scopes the controllers for any routes defined inside its block to a specific subfolder (package) without adding the pack
- [`patch()`](/v3-0-0/configuration/patch/) — Create a route that matches a URL requiring an HTTP <code>PATCH</code> method. We recommend using this matcher to expose
- [`post()`](/v3-0-0/configuration/post/) — Create a route that matches a URL requiring an HTTP <code>POST</code> method. We recommend using this matcher to expose 
- [`put()`](/v3-0-0/configuration/put/) — Create a route that matches a URL requiring an HTTP <code>PUT</code> method. We recommend using this matcher to expose a
- [`resource()`](/v3-0-0/configuration/resource/) — Create a group of routes that exposes actions for manipulating a singular resource. A singular resource exposes URL patt
- [`resources()`](/v3-0-0/configuration/resources/) — Create a group of routes that exposes actions for manipulating a collection of resources. A plural resource exposes URL 
- [`root()`](/v3-0-0/configuration/root/) — Defines a route that matches the root of the current context. This could be the root of the entire application (like the
- [`scope()`](/v3-0-0/configuration/scope/) — The scope() function in Wheels is used to define a block of routes that share common parameters such as controller, pack
- [`set()`](/v3-0-0/configuration/set/) — Used to configure global settings or set default argument values for Wheels functions. It can be applied to core functio
- [`wildcard()`](/v3-0-0/configuration/wildcard/) — Automatically generates dynamic routes for your controllers using placeholders like [controller], [action], and optional
