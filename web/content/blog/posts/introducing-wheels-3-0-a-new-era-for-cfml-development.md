---
title: 'Introducing Wheels 3.0: A New Era for CFML Development'
slug: introducing-wheels-3-0-a-new-era-for-cfml-development
publishedAt: '2026-01-12T04:15:07.000Z'
updatedAt: '2026-01-12T22:45:54.000Z'
author: Peter Amiri
tags:
  - wheels-3-0
  - releases
categories: []
excerpt: >-
  Today, we're thrilled to announce the release of Wheels 3.0 — the most
  significant update in the framework's history. This release marks not just a
  version bump, but a complete evolution of the pro...
coverImage: null
legacyId: '134'
---
Today, we're thrilled to announce the release of Wheels 3.0 — the most significant update in the framework's history. This release marks not just a version bump, but a complete evolution of the project, including a rebrand from CFWheels to simply Wheels.

# A Fresh Identity

With version 3.0, we've embraced a new identity:

  * New Name: CFWheels → Wheels
  * New Domain: https://wheels.dev (from cfwheels.org)
  * New Home: https://github.com/wheels-dev/wheels

This rebrand reflects our commitment to modernization while honoring our Rails-inspired heritage. Wheels continues to be the convention-over-configuration MVC framework that makes CFML development a joy.

**What's New in 3.0**

*Modernized Architecture*

The project structure has been completely redesigned for cleaner separation of concerns:

  * Core Outside App Root: Wheels core now lives in /vendor/wheels, keeping your application code cleanly separated from framework internals
  * Updated Mappings: Simplified Application.cfm configuration
  * Modular Design: Better support for modern dependency management

# Powerful New CLI

The wheels CLI has been completely rewritten with powerful new commands:

**Initialize project with Docker support**
wheels docker init

**Environment management**
wheels env setup

**Database operations (now with Oracle support!)**
wheels db create
wheels db drop

**Run tests with watch mode**
wheels test run
wheels test watch

**Generate scaffolds, models, controllers, and more**
wheels g scaffold Post properties="title:string,content:text,published:boolean"

**Expanded Database Support**
Wheels 3.0 runs on more databases than ever:

  * Oracle: Full support in CLI and ORM
  * SQLite: New adapter with automatic datetime handling
  * MySQL, PostgreSQL, SQL Server, H2: Updated to latest versions

**BoxLang Compatibility**

Looking to the future? Wheels 3.0 is compatible with https://boxlang.io, the next-generation JVM language from Ortus Solutions. Run your Wheels apps on Lucee, Adobe ColdFusion, or BoxLang — your choice.

**Enhanced Model Layer**

  * ignoreColumns(): New method to exclude specific columns from ORM mapping
  * Race Condition Handling: Improved model initialization with automatic recovery
  * Performance Boost: Significant findAll() optimizations
  * Native Query Support: Better returnType handling

**Modern Testing Infrastructure**

  * Rewritten TestUI: Beautiful Vue-based test runner interface
  * TestBox 6.0: Updated to the latest TestBox with full BDD support
  * Expanded Matrix: Tested on Lucee 5/6/7, Adobe ColdFusion 2021/2023/2025, and BoxLang

**Developer Experience**

  * VSCode Extension: New extension with IntelliSense, snippets, and API documentation
  * macOS Installer: One-click installation for Mac developers
  * MCP Integration: AI-assisted development with Model Context Protocol support

# Getting Started

*New Projects*

**Install the CLI**
box install wheels-cli

**Create a new Wheels 3.0 application**
wheels g app myapp
cd myapp
server start

**Upgrading from 2.x**

Before upgrading, review the breaking changes:

1. Project Structure: Update your Application.cfm mappings for the new core location
2. Dependencies: Wheels 3.0 requires WireBox 7.0+ and TestBox 6.0+
3. Migrations: The null parameter is now allowNull

See our https://wheels.dev/3.0.0/guides/introduction/upgrading for detailed instructions.

# Thank You

Wheels 3.0 represents months of work from our incredible community. Special thanks to:

* Zain Ul Abideen for the tireless CLI development, BoxLang compatibility, Oracle support, and countless improvements
* Peter Amiri for architecture redesign, release infrastructure, and MCP integration
* Adam Chapman for the ignoreColumns() feature and model enhancements
* MvdO79 for documentation improvements and beginner tutorials
* All our contributors, testers, and community members

Links

* Website: https://wheels.dev
* GitHub: https://github.com/wheels-dev/wheels
* Documentation: https://wheels.dev/guides
* Release Notes: https://github.com/wheels-dev/wheels/blob/main/CHANGELOG.md
* ForgeBox: box install wheels

What's Next

We're already planning Wheels 3.1 with more features and improvements. Join our community, file issues, submit PRs, and help shape the future of CFML development.

Happy coding!

*The Wheels Team*
