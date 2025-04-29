# CLI Commands

The command line tools extends the functionality of [CommandBox](https://www.ortussolutions.com/products/commandbox) with some commands specifically designed for Wheels development.

[CommandBox](https://www.ortussolutions.com/products/commandbox) brings a whole host of command line capabilities to the CFML developer. It allows you to write scripts that can be executed at the command line written entirely in CFML. It allows you to start a CFML server from any directory on your machine and wire up the code in that directory as the web root of the server. What's more is, those servers can be either Lucee servers or Adobe ColdFusion servers. You can even specify what version of each server to launch. Lastly, CommandBox is a package manager for CFML. That means you can take some CFML code and package it up into a module, host it on ForgeBox.io, and make it available to other CFML developers. In fact we make extensive use of these capabilities to distribute Wheels plugins and templates. More on that later.

One module that we have created is a module that extends CommandBox itself with commands and features specific to the Wheels framework. The Wheels CLI module for CommandBox is modeled after the Ruby on Rails CLI module and gives similar capabilities to the Wheels developer.

### Install CommandBox

The first step is to get [CommandBox](https://www.ortussolutions.com/products/commandbox) downloaded and running. CommandBox is available for Windows, Mac & Linux, and can be installed manually or using one of the respective package managers for each OS. You can use [Chocolatey](https://chocolatey.org) on Windows, [Homebrew](https://brew.sh) on MacOS, or Yum/Apt on Linux depending on your flavor of Linux. Please follow the instructions on how to install CommandBox on your particular operating system. At the end of the installation process you want to make sure the `box` command is part of your system path so you can call the command from any directory on your system.

Once installed, you can either double-click on the `box` executable which opens the CommandBox shell window, or run `box` from a CMD window in Windows, Terminal window in MacOS, or shell prompt on a Linux server. Sometimes you only want to call a single CommandBox command and don't need to launch a whole CommandBox shell window to do that, for these instances you can call the CommandBox command directly from your default system terminal window by prefixing the command with the `box` prefix.

So to run the CommandBox `version` command you could run box version from the shell or you could launch the CommandBox shell and run version inside it.

{% tabs %}
{% tab title="Shell" %}
box version
{% endtab %}

{% tab title="CommandBox" %}
version
{% endtab %}
{% endtabs %}

This is a good concept to grasp, cause depending on your workflow, you may find it easier to do one versus the other. Most of the commands you will see in these CLI guides will assume that you are entering the command in the actual CommandBox shell so the `box` prefix is left off.

### Install the wheels-cli CommandBox Module

Okay, now that we have CommandBox installed, let's add the Wheels CLI module.

{% tabs %}
{% tab title="CommandBox" %}
install wheels-cli
{% endtab %}
{% endtabs %}

Installing this module will add a number of commands to your default CommandBox installation. All of these commands are prefixed by the `wheels` name space. There are commands to create a brand new Wheels application or scaffold out sections of your application. We'll see some of these commands in action momentarily.

These tools allow you to adopt a more modern workflow and allow you to create and manipulate many Wheels objects from the command line. By making these tools available in the command line, not only will you be able to speed up your development but you can also utilize these commands in Continuous Integration (CI) and Continuous Deployment (CD) work flows.

* [wheels - commands](wheels-commands.md)
* [wheels generate - commands](wheels-generate-commands.md)
* [wheels dbmigrate - commands](wheels-dbmigrate-commands.md)
* [wheels plugins - commands](wheels-plugins-commands.md)
