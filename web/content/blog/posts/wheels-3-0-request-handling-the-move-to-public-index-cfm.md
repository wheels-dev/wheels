---
title: 'Wheels 3.0 Request Handling: The Move to public/index.cfm'
slug: wheels-3-0-request-handling-the-move-to-public-index-cfm
publishedAt: '2026-01-20T12:50:39.000Z'
updatedAt: '2026-01-20T17:50:39.000Z'
author: Zain Ul Abideen
tags:
  - wheels-3-0
  - request-handling
  - front-controller
  - public-index-cfm
  - application-architecture
categories: []
excerpt: >-
  One of the most fundamental changes in Wheels 3.0 is how incoming HTTP
  requests enter your application. While this change is easy to overlook, it
  directly impacts routing, security, deployment, and...
coverImage: null
legacyId: '136'
---
One of the most fundamental changes in Wheels 3.0 is how incoming HTTP requests enter your application. While this change is easy to overlook, it directly impacts routing, security, deployment, and mental model clarity.  
In Wheels 3.0, all web requests now flow through a single entry point: \*\*public/index.cfm\*\*  
This article explains: \* How request handling worked in Wheels 2.5 \* What changed in Wheels 3.0 \* Why this change was necessary \* How it improves security and predictability \* What this means for your applications going forward # \*\*How Request Entry Worked in Wheels 2.5\*\* In Wheels 2.5, request handling relied on multiple files at the application root, most notably: \* root.cfm \* rewrite.cfm \* .htaccess (or web server rewrites) Depending on your server configuration and rewrite rules, requests could pass through different files before reaching the framework. While this worked, it introduced several issues: \* Multiple “entry points” into the application \* Harder-to-reason-about execution flow \* Increased risk of exposing internal files \* Confusion for new developers \* Differences in behavior across servers and environments In short, \*\*the request lifecycle was implicit\*\*, not obvious.  
  
\# \*\*What Changed in Wheels 3.0\*\* Wheels 3.0 introduces a single, \*\*explicit request entry point\*\*: \`/public/index.cfm\`. All HTTP requests are now routed through this file. Key changes: \* \`index.cfm\` lives inside the public directory \* Only the public directory is meant to be web-accessible \* Internal application files are no longer directly reachable \* Routing begins in one predictable place, every time This aligns Wheels with modern framework conventions and removes ambiguity from request handling.  
  
\# \*\*Why This Change Matters\*\* \*\*One Entry Point = Predictability\*\* With a single entry file: \* Every request starts the same way \* Debugging becomes easier \* Middleware, routing, and lifecycle hooks behave consistently There is no longer a need to mentally trace whether a request went through \`root.cfm\`, \`rewrite.cfm\`, or both.  
  
\# \*\*Improved Security by Default\*\* By serving only the \*\*public directory\*\*: \* Internal files (\`app/\`, \`config/\`, \`vendor/\`) are never exposed \* Accidental access to framework internals is eliminated \* Safer defaults for production environments This is a major improvement over Wheels 2.5, where misconfigured servers could expose sensitive files.  
  
\# \*\*Clear Separation Between Web and Application Code\*\* In Wheels 3.0: \* public/ contains only what the web server should serve \* Application logic lives elsewhere \* The framework controls the request lifecycle from the moment it enters the app This separation is intentional and foundational to the 3.0 architecture.  
  
\# \*\*Better Alignment with Modern Frameworks\*\* Frameworks like Rails, Laravel, Django, and Phoenix all use a single front controller pattern. Wheels 3.0 adopts this same approach, making the framework: \* Easier to understand for developers coming from other ecosystems \* Easier to deploy on modern hosting platforms \* Easier to reason about in CI/CD pipelines # \*\*What Happens Inside public/index.cfm\*\* The index.cfm file acts as the front controller. Its responsibilities include: \* Bootstrapping the application \* Loading configuration \* Initializing the framework \* Dispatching the request to the appropriate controller/action \* Ensuring consistent lifecycle execution While you generally won’t need to modify this file, its presence provides a \*\*clear and intentional starting point\*\* for every request.  
  
\# \*\*Deployment Implications\*\* To use Wheels 3.0 correctly, your web server should be configured so that the document root points to: \`/public\`. All requests are routed through \`index.cfm\`. This applies whether you’re using: \* CommandBox \* Apache \* Nginx \* IIS \* Docker-based deployments Once configured, Wheels handles routing internally — no additional rewrite files are required inside the application root.  
  
\# \*\*Migrating from Wheels 2.5\*\* When upgrading: \* Remove reliance on root.cfm and \`rewrite.cfm\` \* Update your web server’s document root to \`public/\` \* Verify that no application files outside \`public/\` are directly accessible Most applications will benefit immediately from: \* Cleaner URLs \* Safer defaults \* Fewer environment-specific edge cases # \*\*Summary\*\* The move to \`public/index.cfm\` in Wheels 3.0 may seem small, but it sets the foundation for: \* Predictable request handling \* Stronger security \* Cleaner application structure \* Easier debugging \* Modern deployment workflows This change reflects a broader theme in Wheels 3.0: making the framework \*\*explicit, intentional, and easier to reason about\*\* — starting from the very first line of code that runs.
