---
description: How to publish your plugin to forgebox.io via CommandBox
---

# Publishing Plugins

So, you've created your new magic, world solving plugin, and naturally, you want to share it with the world. Wheels uses [forgebox.io](https://www.forgebox.io/type/wheels-plugins) as a plugins repository. This enables us to manage our Wheels application's dependencies, install updates easily via CommandBox and more.

As a plugin author, it's well worth spending a little time setting yourself up to work with forgebox with the minimum amount of effort. Once done, you'll be able to either publish directly from the commandline, or upload to forgebox manually.

This tutorial makes extensive use of CommandBox, GIT and the Wheels CLI.

### Requirements

We strongly recommend always having the latest version of [CommandBox](https://www.ortussolutions.com/products/commandbox).

You'll also want the Wheels CLI. You can install that in CommandBox via `install wheels-cli`. This will also update it if you've got an older version installed.

Some scripted commands also require the git CLI, although these are technically optional.

### Setup a forgebox user account

If you've not got a [forgebox.io](http://forgebox.io/) account you can either [register directly on forgebox](https://www.forgebox.io/security/registration) or very quickly via CommandBox itself

{% code title="CommandBox" %}
```shell
# Register for an account
$ forgebox register
```
{% endcode %}

Once you've got your credentials, you should be good to go.

If you've already got an account, you need to login at least once, which will store an API token for future use:

{% code title="CommandBox" %}
```shell
# Login
$ forgebox login

# (optional) Check which account you're logged in with
$ forgebox whoami
```
{% endcode %}

### Ensure you've got a box.json in your plugin root

Forgebox uses your local `box.json` - you'll need one! Critical package information like the name of your plugin and the location are stored here. You can create one manually, or you can run:

{% code title="Shell" %}
```shell
# Create a basic box.json
$ init

# Or pass in parameters at the same time
$ init name="My Funky Plugin" slug=my-funky-plugin version=1.0.0 type="wheels-plugins"

# Or use the wizard
$ init --wizard
```
{% endcode %}

### Ensure you've set some critical box.json attributes

In order for other Wheels users to quickly identify and install your plugin via the Wheels CLI, make sure you set the following `box.json` attributes - whilst a standard `box.json` might only have `name, version,author`, we need a little more information. Here's a template to get you started: (replace the values in CAPS)

{% code title="box.json" %}
```json
{
  // Required:
 "name":"PLUGIN-NAME",
 "version":"0.0.1",
 "author":"YOURNAME",
  // Required: GitHub Repository stub
 "location":"GITHUBUSERNAME/GITHUB-REPONAME#v0.0.1",
  // Required: Should always be /templates/base/src/app/plugins/
 "directory":"/templates/base/src/app/plugins/",
  // Required: Should always be true
 "createPackageDirectory":true,
  // Required: Must be the name of your primary CFC File
 "packageDirectory":"PLUGIN-NAME",
  // Required: The Forgebox slug, must be unique
 "slug":"FORGEBOX-SLUG",
  // Required: Must be wheels-plugins
 "type":"wheels-plugins",
  // Required: From here is optional but recommended
 "homepage":"https://github.com/GITHUBUSERNAME/GITHUB-REPONAME",
 "shortDescription":"PLUGIN DESCRIPTION",
 "keywords":"KEYWORD",
 "private":false,
 "scripts":{
   "postVersion":"package set location='GITHUBUSERNAME/GITHUB-REPONAME#v`package version`'",
 "patch-release":"bump --patch",
 "minor-release":"bump --minor",
 "major-release":"bump --major",
 "postPublish":"!git push --follow-tags && publish"
  }
}
```
{% endcode %}

Your completed `box.json` might look something like this:

{% code title="box.json" %}
```json
{
  // Required:
 "name":"Shortcodes",
 "version":"0.0.4",
 "author":"Tom King",
  // Required: GitHub Repository stub, including version hash
 "location":"neokoenig/wheels-shortcodes#v0.0.4",
  // Required: Should always be /templates/base/src/app/plugins/
 "directory":"/templates/base/src/app/plugins/",
  // Required: Should always be true
 "createPackageDirectory":true,
  // Required: Must be the name of your primary CFC File
 "packageDirectory":"Shortcodes",
  // Required: The Forgebox slug, must be unique
 "slug":"shortcodes",
  // Required: Must be wheels-plugins
 "type":"wheels-plugins",
  // Required: From here is optional but recommended
 "homepage":"https://github.com/neokoenig/wheels-shortcodes",
 "shortDescription":"Shortcodes Plugin for Wheels",
 "keywords":"shortcodes",
 "private":false,
 "scripts":{
   "postVersion":"package set location='neokoenig/wheels-shortcodes#v`package version`'",
 "patch-release":"bump --patch",
 "minor-release":"bump --minor",
 "major-release":"bump --major",
 "postPublish":"!git push --follow-tags && publish"
  }
}
```
{% endcode %}

### Using the forgebox staging server (optional)

If this is the first time you've done this, you might want to try the forgebox staging server. That way you can make sure your publishing process is spot on without having lots of unnecessary versions pushed up. You can view the staging server version at [http://forgebox.stg.ortussolutions.com/](http://forgebox.stg.ortussolutions.com/)

{% code title="CommandBox" %}
```shell
# Add staging server configuration
$ config set endpoints.forgebox.APIURL=http://forgebox.stg.ortussolutions.com/api/v1

# Revert back to production configuration
$ config clear endpoints.forgebox.APIURL
```
{% endcode %}

Remember this configuration will "stick", so make sure you change it back afterwards. (I find once changed, it might not kick in until you reload the CommandBox shell via `r`).

### Publishing a plugin to forgebox

Both Wheels CLI and Forgebox are expecting a tagged release with the plugin contents (e.g. zip). So the best way to publish is to...

1. Navigate into the plugin directory
2. Ensure that directory is authorized to publish the repo (e.g. `git remote -v` should list your fetch/push endpoints)

> Note: Git dislikes nested repos, so it's best to setup a test wheels site specifically for plugin development/deployment. Then `git init` within each plugin directory itself, but not at the root. (e.g. `/templates/base/src/app/plugins/PluginName/`)

{% code title="CommandBox" %}
```shell
# from CommandBox prompt, within plugin directory
$ run-script patch-release
```
{% endcode %}

ForgeBox does not store your actual package files like npm, but points to your download location.&#x20;

The following should happen (again, assuming you have git publish rights from that plugin directory)

1. Auto increment your version number within box.json
2. Push updated box.json to forgebox (with new version number + location)
3. Create a git "Tagged Release" which is basically a zip containing the source files

Once you run this command, you can run `forgebox show my-package` to confirm it's there. If you change the slug, a new package will be created. If you change the version, a new version will be added to the existing package.

### Adding a new version via publishing scripts

By adding the following block to our `box.json`, we can more easily deploy new versions with a single command:

{% code title="box.json" %}
```json
"scripts":{
    "postVersion":"package set location='GITHUBUSERNAME/GITHUB-REPONAME#v`package version`'",
    "patch-release":"bump --patch",
    "minor-release":"bump --minor",
    "major-release":"bump --major",
    "postPublish":"!git push --follow-tags && publish"
  }
```
{% endcode %}

Obviously, you'll need to change `location='GITHUBUSERNAME/GITHUB-REPONAME#v` to your repo.

With these in place, **once you've committed your changes to your local repository**, you can now do:

{% code title="CommandBox" %}
```shell
# Don't forget to commit your changes. You can access git directly from commandbox using !
$ !git add .
$ !git commit -m "my new changes"

# Move from 1.0.0 -> 1.0.1
$ run-script patch-release

# Move from 1.0.0 -> 1.1.0
$ run-script minor-release

# Move from 1.0.0 -> 2.0.0
$ run-script major-release
```
{% endcode %}

This will:&#x20;

* Set the package location to include the new version number
* Publish to forgebox.io
* Push your changes to gitHub (assuming you've set that up)&#x20;
* Publish a gitHub tagged release

This saves you having to manually update the version number too!

{% code title="Commandbox" %}
```shell
# Example output of a patch release
$ run-script patch-release

Running package script [patch-release].
> bump --patch && publish
Set version = 0.1.7

Running package script [postVersion].
> package set location='neokoenig/wheels-cli#v`package version`'
Set location = neokoenig/wheels-cli#v0.1.7
Package is a Git repo.  Tagging...
Tag [v0.1.7] created.
Sending package information to ForgeBox, please wait...
Package is alive, you can visit it here: https://www.forgebox.io/view/wheels-cli

Running package script [postPublish].
> !git push --follow-tags
Counting objects: 10, done.
Delta compression using up to 12 threads.
Compressing objects: 100% (8/8), done.
Writing objects: 100% (10/10), 908 bytes | 0 bytes/s, done.
Total 10 (delta 5), reused 0 (delta 0)
remote: Resolving deltas: 100% (5/5), completed with 4 local objects.
To https://github.com/neokoenig/wheels-cli.git
   477648f..400604b  master -> master
 * [new tag]         v0.1.7 -> v0.1.7

Package published successfully in [forgebox]
```
{% endcode %}

Lastly, you can double check it's made it into the plugins list via `wheels plugins list`

### Removing a plugin from forgebox

Likewise, you can unpublish a plugin, but keep in mind people might be relying on your plugin, so don't do this lightly!

{% code title="CommandBox" %}
```shell
// Remove all versions of a package
$ unpublish

// Remove a specific version of a package
$ unpublish 1.2.3

// Skip the user confirmation prompt
$ unpublish 1.2.3 --force
```
{% endcode %}
