---
title: 'Wheels 3.0 Project Structure: What Changed and Why It Matters'
slug: wheels-3-0-project-structure-what-changed-and-why-it-matters
publishedAt: '2026-01-15T10:49:58.000Z'
updatedAt: '2026-01-15T15:49:58.000Z'
author: Zain Ul Abideen
tags:
  - wheels-3-0
  - project-structure
  - framework-architecture
  - application-layout
  - developer-experience
categories:
  - Documentation
  - Releases
excerpt: >-
  One of the first noticeable differences when you start building applications
  with Wheels 3.0 is the way your project is laid out. This change may seem
  small at first glance, but it has a significan...
coverImage: null
legacyId: '135'
---
One of the first noticeable differences when you start building applications with Wheels 3.0 is the way your project is laid out. This change may seem small at first glance, but it has a significant impact on clarity, security, and maintainability compared to Wheels 2.5.

In this article, we’ll explore:
* What changed
* Why it matters
* How it affects your development workflow
* Practical steps when starting a new project

Let’s dive in.

# **What Changed in Wheels 3.0**
In Wheels 3.0, the framework core is separated from your application code in a clear and intentional way:
* Core framework files now live under vendor/wheels instead of being mixed into the application root.
* Only the essential application folders remain at the root.
* Static assets, configuration, and app code each live in well-defined places.

This change makes your project easier to understand and harder to accidentally modify your framework internals.

Here's what the major change means in practice:
# **Before (Wheels 2.5):**
* Framework files were inside the project root
* Application and framework files lived beside each other
* Harder to distinguish app code from framework code

# **Now (Wheels 3.0):**
* Core Wheels files are under: **vendor/wheels**
* App code lives under: **app/controllers**, **app/models**, **app/views**
* Public assets live in: **public/**
* Configuration stays clean in: **config/**
* Tests and support files also have their own folders

This creates a clear **separation of concerns** between your code and the framework itself.

# **Why This Matters**

**1. Cleaner Application Root**

Your project’s root folder now contains only what you are responsible for — configs, public assets, and your business logic. This reduces clutter and makes onboarding easier for new developers.

**2. Better Security and Maintainability**

Separating framework files into vendor/wheels means your core framework files aren’t directly modified during development. Updates and upgrades become safer and more predictable.

**3. Improved Tooling Compatibility**

Tools like dependency managers, linters, and CI/CD pipelines expect clear boundaries in a project structure. With the new layout, automation becomes easier to implement and maintain.

**4. Standardized App Layout**

Wheels 3.0 aligns more with conventions seen in other modern frameworks — where core dependencies are isolated and app code lives in a predictable structure.
If you’ve ever used frameworks like Ruby on Rails, Laravel, or Django, this feels instantly familiar — and that’s by design.

**Working With the New Structure**

When you generate a new Wheels 3.0 project using the CLI, this structure is set up automatically:

```
wheels g app myapp
cd myapp
server start
```

Once created, you’ll see:

```
/app
  /controllers
  /models
  /views
/config
/public
/tests
/vendor
  /wheels
```


**Key folders explained:**

**app/:**                                 Your controllers, models, and views

**config/:**                             Application configuration

**public/:**                             Static assets and entry point (index.cfm)

**vendor/wheels/:**             The Wheels framework code

**tests/:**                              	Test suite (TestBox etc.)

This structure empowers you to maintain clean code boundaries while keeping your application logical and organized.

**When You Should Care**

You’ll immediately see benefits from this structure:
* When starting a new project
* When upgrading from Wheels 2.5
* When setting up version control
* During code reviews
* When training new developers
It reduces accidental edits to core files and sets a clear path for scaling your project.

**In Summary**

Wheels 3.0’s revised project structure — where the core framework lives under vendor/wheels and your application is cleanly separated — is one of the most foundational changes you’ll notice as a developer.
This change delivers:
* Cleaner project roots
* Better separation of concerns
* Easier upgrades
* And a structure that scales with your application

If you want a framework that feels organized from day one, this update sets the tone for all your future work in Wheels 3.0.
