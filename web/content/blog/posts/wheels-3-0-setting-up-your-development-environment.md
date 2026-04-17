---
title: 'Wheels 3.0: Setting Up Your Development Environment'
slug: wheels-3-0-setting-up-your-development-environment
publishedAt: '2025-03-15T22:42:56.000Z'
updatedAt: '2025-06-02T13:05:31.000Z'
author: Peter Amiri
tags:
  - 2-5
  - 3-0
  - cfwheels
  - cli
  - wheels
  - wheels-3-0
categories: []
excerpt: Accompanying Video
coverImage: null
legacyId: '130'
---

## Accompanying Video

This blog post has an accompanying video posted to [YouTube](https://youtu.be/-76Z_N27siE).

## Introduction

The forthcoming release of the Wheels 3.0 framework is creating waves in the development community, promising transformative enhancements and simplified workflows. In this blog post, we will focus on establishing the foundational environment crucial for executing Wheels projects efficiently. We'll guide you through project creation using both the current and the upcoming 3.0 versions of the framework and will explore the differences in their directory structures. Let's dive right in!

## Installing CommandBox

The cornerstone of our setup is CommandBox, a versatile tool that modernizes the CFML developer's workflow. CommandBox serves as a command line shell, a package manager, and a seamless interface to start a CFML engine in any given directory, without the need to juggle complex application server installations. CommandBox is accessible for Mac, Windows, and Linux OS, with installation methods varying accordingly. For Mac users like me, Homebrew is the chosen method for installation, while Windows users can turn to Chocolaty or a native installer, and Linux enthusiasts can rely on built-in package managers.

## CommandBox and Wheels CLI Setup

Once CommandBox is installed, jump into the CommandBox shell via the \`BOX\` command in the terminal window. Note that the first launch involves downloading several packages which could take some time. Following the setup, install the Wheels CLI commands into CommandBox using \`INSTALL WHEELS-CLI\`. Although I've already completed this step earlier, executing this ensures you are equipped with the right tools to proceed.

## Creating Projects with Wheels

With CommandBox ready, embark on creating two projects using the \`WHEELS NEW\` command. This command initiates a wizard that will actively guide you through the process of setting up a new Wheels project.

## 1\. Creating a Current Version Project

1.  **Naming the Project**: First, supply a name for the project, for instance, "CURRENT", which creates a directory embodying the project files.
2.  **Template Selection**: Choose the template corresponding to the current version and proceed with the default options.
3.  **Project Initialization**: Conclude the process with a "Yes" to affirm configuration and initiate project setup. The CLI will create the project directory and integrate necessary files. Launch the server with \`START\` and witness the "Congratulations" page, assuring correct installation.

## 2\. Creating a Wheels 3.0 Version Project

1.  **Naming the Project**: Again, deploy \`WHEELS NEW\` to name your project.
2.  **Template Selection**: This time, select the "Bleeding Edge" template for a Wheels 3.0 implementation. Confirm defaults and proceed to build your project.
3.  **Project Initialization**: Use the \`START\` command to usher in a new CFML application server, culminating in a fresh "Congratulations" page highlighting the new branding and 3.0 framework base.

## Exploring Directory Structures

A crucial step is to delve into the structural differences between the two projects:

1.  **Current Version**: This project exhibits a larger assortment of directories and files at its root, which poses an increased potential attack surface.
2.  **Wheels 3.0**: The new framework refines this exposure significantly, only housing four directories at the root. Key directories like config, controllers, and views reside under the \`app\` directory, while static resources like images and stylesheets find home under the \`public\` directory. The \`vendor\` directory now accommodates core framework files, enhancing security by mapping only the public folder to the webroot of the application server.

## Conclusion

Setting up an environment for Wheels 3.0 marks the beginning of an exciting journey in CFML development. From installing CommandBox to exploring framework nuances, we have geared up for advanced Wheels projects.
