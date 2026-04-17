---
title: Creating a Basic CRUD Interface with Wheels 3.0
slug: creating-a-basic-crud-interface-with-wheels-3-0
publishedAt: '2025-07-17T19:01:13.000Z'
updatedAt: '2025-07-17T19:01:13.000Z'
author: Peter Amiri
tags:
  - 3-0
  - cfwheels
  - crud
  - wheels
  - wheels-3-0
  - wheels-dev
categories: []
excerpt: Accompanying Video
coverImage: null
legacyId: '131'
---
## Accompanying Video

This blog post has an accompanying video posted to [YouTube](https://youtu.be/paUjKmYZnrU).

  

##   

Welcome to the next installment in our Wheels 3.0 tutorial series! Today, we’ll guide you through creating a basic CRUD (Create, Read, Update, Delete) interface using the Wheels CLI. If you're just joining us and don't have the Wheels CLI installed yet, be sure to catch up with our previous video detailing the setup of your development environment.

## Setting Up Your Wheels Project

To get started, we activate the \`WHEELS NEW\` command, which launches a wizard designed to help us build a new Wheels project efficiently. First, provide a name for your application—I'll be using "myapp" as the demonstration name.

During the setup, you'll be prompted to select which Wheels version to install, and we’ll choose the second option for Wheels 3.0. For development purposes, we'll leave the reload password empty, but remember to set a secure password before moving to production. Next, the wizard will ask for a datasource name, which defaults to our application name and suits our needs.

You’ll then be asked to select a CFML engine for deployment, and we’ll stick with the default, the latest version of Lucee. Since we opted for the Lucee engine, it offers the use of a built-in H2 database—a great development option that avoids setting up a separate database server. We’ll go ahead and select “yes” to use it.

You'll have the option to include the Bootstrap CSS framework to enhance the appearance of your app. Finally, decide whether you want a box.json file for uploading the project to Forgebox.io. For this project, I’ll choose “no.”

After confirming our settings, the wizard will download the specified 3.0 template, along with any necessary dependencies, setup the H2 database, integrate Bootstrap, and start the server. Once the installation is complete, we can explore what’s been set up.

## Exploring the CLI Setup

The CLI generates a default Wheels installation skeleton, which it modifies based on our inputs, such as updating configuration files and creating essentials like the URL rewrite file and a server.json file.

Upon successful installation, the confirmation screen assures us with a set of configurations displayed on the Info tab. This includes details like application and datasource names, and confirms the H2 database driver installation with the ready-to-use datasource.

## Creating a User Model

Now, it’s time to create users through the CLI. In CommandBox, we use the \`wheels scaffold\` command to begin creating a User model. We’ll bypass the database migration initially but note how this step has generated skeleton view files, a model file, and a controller in the app. This default setup is crucial for the business logic and user interactions.

To give the user model some structure, we use the command line to add properties like first name, last name, and email to the User model, although we'll skip database migrations for these incremental property additions.

## Consolidating Migration Files

Before executing database migrations, it’s wise to consolidate the migration files generated. Inside the app's migrator/migrations folder are several CFC files. We aim to merge these into a single file, ensuring the \`up\` and \`down\` functions are properly matched—creating a table in \`up\` and dropping it in \`down\`.

Once consolidated, enhance the migration script by adding string-based columns for first and last names with a character limit, and a longer limit for emails, ensuring database integrity and conformity.

## Running Migrations

Migrations can be executed via the CLI or the application's user interface. Using the UI, navigate to the Migrator tab and run the migrations in sequence or opt for 'Migrate to Latest’ to process all migrations.

Given that model configurations are cached, reload the application post-migration to let the framework update model configurations based on new database structures.

## Finalizing the Application

Lastly, make the User index the default application page rather than the Congratulations page. Modify the routes.cfm file to direct URLs to the users index route by default. Reload the application to apply this routing change, and upon revisiting the default route, the Users page should now load by default.

This tutorial concludes our hands-on exploration of CRUD interface creation in Wheels 3.0 using CLI. We covered project setup, database configuration, scaffolding models, property additions, migration management, and front-end interfacing—all culminating in a functional application displaying user data.
