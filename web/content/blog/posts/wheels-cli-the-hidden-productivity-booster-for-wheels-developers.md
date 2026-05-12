---
title: 'Wheels CLI: The Hidden Productivity Booster for Wheels Developers'
slug: wheels-cli-the-hidden-productivity-booster-for-wheels-developers
publishedAt: '2026-02-16T21:57:25.337Z'
updatedAt: '2026-02-16T21:57:25.345Z'
author: Zain Ul Abideen
tags:
  - wheels-cli
  - cli
  - cli-commands
  - productivity
categories: []
excerpt: >-
  \ Introduction Wheels Framework is already known for rapid development, but
  when combined with the \Wheels CLI\(/guides/command-line-tools/cli-overview),
  productivity increases dramatically. Many d...
coverImage: null
legacyId: '139'
---

\# Introduction Wheels Framework is already known for rapid development, but when combined with the \[Wheels CLI\](/guides/command-line-tools/cli-overview), productivity increases dramatically.

Many developers either don’t use the CLI often or don’t fully explore its capabilities. That’s a missed opportunity — because the CLI is one of the biggest workflow accelerators in the Wheels ecosystem.

This article focuses on the classic Wheels CLI commands — the ones that have been around for a long time and are still fully functional in Wheels 3.0. While Wheels 3.0 introduces new tooling and improvements (which we’ll cover in the next article), these commands remain reliable and widely used.

They are powerful for: \* Bootstrapping projects \* Scaffolding entities \* Managing database migrations \* Generating code \* Handling plugins \* Speeding up daily development tasks If you’re maintaining existing projects or want to master the foundations first, these commands are essential.

\# What is Wheels CLI? Wheels CLI is a command-line toolkit that automates repetitive tasks in Wheels applications. Instead of manually creating files, writing boilerplate code, or managing database changes, you can do it in seconds using simple commands. It promotes convention, structure, and repeatability across projects.

Benefits: \* Less manual work \* Fewer mistakes \* Consistent structure \* Faster onboarding for new developers \* Rapid prototyping # Quick Start Guide You can get started with Wheels CLI in just a few minutes. Prerequisites: \* CommandBox 5.0+ \* Java 17+ \* Database (MySQL, PostgreSQL, SQL Server, Oracle, SQLite, or H2) # Installation Wheels CLI runs on CommandBox, so you need CommandBox installed first. CommandBox is a CLI tool for CFML that helps you manage: \* Servers \* Packages \* Dependencies \* Frameworks like Wheels. You can follow the official \[quick start guide\](https://wheels.dev/guides/command-line-tools/quick-start). This guide shows how to install CommandBox and set up the Wheels CLI. Once CommandBox is installed, you can use Wheels CLI commands inside your project directory.

\# Classic Wheels CLI Commands (Still Working in Wheels 3.0) These commands form the backbone of many Wheels workflows and remain supported in Wheels 3.0. # 1. Wheels Init \`wheels init\`  
Bootstrap an existing Wheels application for CLI usage. The wheels init command initializes an existing Wheels application to work with the Wheels CLI. It's an interactive command that helps set up necessary configuration files (box.json and server.json) for an existing Wheels installation.

Great for: \* Starting fresh projects \* Standardizing setups across teams # 2. Wheels Info \`wheels info\`  
The wheels info command displays information about the Wheels CLI module and identifies the Wheels framework version in the current directory.

Helpful for: \* Debugging \* Checking versions \* Environment awareness # 3. Wheels Reload \`wheels reload\`  
The wheels reload command reloads your Wheels application, clearing caches and reinitializing the framework. This is useful during development when you've made changes to configuration, routes, or framework settings. Note: the server must be running for this command to work.

Useful when: \* Updating configs \* Testing changes quickly \* Developing actively # 4. Wheels Deps \`wheels deps\`  
The wheels deps command provides a streamlined interface for managing your Wheels application's dependencies through box.json. It integrates with CommandBox's package management system while providing Wheels-specific conveniences. It manages application dependencies using box.jsons.

\# 5. Wheels Destroy The wheels destroy command removes all files and code associated with a resource that was previously generated. It's useful for cleaning up mistakes or removing features completely. This command will also drop the associated database table and remove resource routes.

Example:  
\`wheels destroy model User\`  
Useful when: \* Refactoring \* Cleaning prototypes \* Undoing mistakes # 6. Wheels Generate This is where the magic happens. The Wheels generate command is a productivity-focused code generator that creates common application components following Wheels conventions.

It helps you scaffold structured, ready-to-use code so you don’t have to write repetitive boilerplate manually. Everything it generates aligns with Wheels’ MVC patterns and naming conventions. This makes your codebase consistent and easier to maintain, especially in team environments.

It works by creating files and wiring up basic functionality automatically, allowing developers to focus on business logic instead of setup.  
\*\*Generators:\*\* \* app-wizard \* app \* controller \* model \* property \* route \* scaffold \* code \* snippets \* test \* view Example  
\`wheels generate scaffold post title:string body:text\`  
This generates: \* Model \* Controller \* Views \* Routes \* CRUD setup Huge time saved!

\# 7. Wheels DBMigrate The wheels dbmigrate command provides a structured way to manage database schema changes using migrations. Instead of manually editing databases, you define changes in migration files that can be version-controlled, shared with teams, and safely executed across environments. It brings modern migration workflows (similar to Rails or Laravel) into Wheels development. Each migration has an up and down path, allowing safe rollbacks when needed.

\*\*Commands:\*\* \* wheels dbmigrate up \* wheels dbmigrate down \* wheels dbmigrate reset \* wheels dbmigrate latest \* wheels dbmigrate info \* wheels dbmigrate exec \* wheels dbmigrate create blank \* wheels dbmigrate create table \* wheels dbmigrate create column \* wheels dbmigrate remove table \*\*Why It’s Useful\*\*  
\* Version-controlled DB schema \* Safe rollbacks \* Team collaboration friendly \* Easier deployments \*\*Example\*\*  
\`Wheels dbmigrate create table users\`  
\`Wheels dbmigrate up\`  
Boom — your table is created and tracked.

\# 8. Wheels Plugins List \`wheels plugins list\` The plugins list command displays information about Wheels plugins. By default, it shows plugins installed locally in the /plugins folder. With the --available flag, it queries ForgeBox to show all available cfwheels-plugins packages.

\*\*Encourages:\*\*  
\* Reusability \* Modular development \* Faster feature addition # Important Note on Wheels 3.0 All commands covered in this article are classic commands that continue to work in Wheels 3.0. They are stable, trusted, and widely used in real-world projects. Many production applications still rely on them daily.  
However, Wheels 3.0 also introduces new CLI capabilities and improvements designed for modern workflows.  
In the next article, we’ll explore the new and enhanced CLI commands introduced in Wheels 3.0, how they differ, and when to use them.

\# Conclusion The Wheels CLI is not just a convenience — it's a productivity multiplier.  
Developers who adopt CLI-driven workflows: \* Ship faster \* Maintain cleaner projects \* Reduce repetitive tasks \* Focus more on business logic Mastering these classic commands gives you a strong foundation before moving on to the newer 3.0 features.
