# wheels - commands

These are the top level commands in the `wheels` namespace.

## `wheels info`

This command is the most basic of the commands and other than printing some pretty ASCII art it also displays the Current Working Directory, the CommandBox Module Root which can be handy when trying to diagnose version discrepancies, and lastly the Wheels version currently installed. The version is determined from a variety of sources. First and foremost, if there is a `box.json` file in the `vendor/wheels/` directory the version is extracted from that `box.json`. Alternatively, if there is no `box.json` file in the `wheels/` directory, we look in `vendor/wheels/events/onapplicationstart.cfm` and extract a version number from that file. That is the version number that is displayed on the default congratulations screen by the way. If both of these fail to get us a version number we can use, we ask you to let us know what version of wheels you are using and give you the option of generating a `box.json` file. This is handy for bringing old legacy installations under CLI control.

```
 ,-----.,------.,--.   ,--.,--.                   ,--.            ,-----.,--.   ,--.
'  .--./|  .---'|  |   |  ||  ,---.  ,---.  ,---. |  | ,---.     '  .--./|  |   |  |
|  |    |  `--, |  |.'.|  ||  .-.  || .-. :| .-. :|  |(  .-'     |  |    |  |   |  |
'  '--'\|  |`   |   ,'.   ||  | |  |\   --.\   --.|  |.-'  `)    '  '--'\|  '--.|  |
 `-----'`--'    '--'   '--'`--' `--' `----' `----'`--'`----'      `-----'`-----'`--'
=================================== Wheels CLI ===================================
Current Working Directory: /Users/peter/projects/ws/MyWheelsApp/
CommandBox Module Root: /Users/peter/projects/wheels-cli/
Current Wheels Version in this directory: 3.0.0
====================================================================================
```

## `wheels init`

This will attempt to bootstrap an EXISTING wheels app to work with the CLI.

We'll assume the database/datasource exists and the other config options like reloadpassword is all set up. If there's no box.json, create it, and ask for the version number if we can't determine it. If there's no server.json, create it, and ask for cfengine preferences. We'll ignore other templating objects for now, as this will probably be in place too.

## `wheels reload`

This command will reload your Wheels application. In order for this command to work, your local server needs to be started and running. This command basically issues a request to the running Wheels application to reload as if you were doing it from your browsers address bar. You will be prompted for your reload password that will be passed to the reload endpoint.

```
wheels reload [mode]
```

| Parameter | Required | Default     | Description                                                   |
| --------- | -------- | ----------- | ------------------------------------------------------------- |
| mode      | false    | development | possible values development, testing, maintenance, production |

## `wheels test`

This command will call the Test Runner in a running server and return the results. The command can be run from within the directory of the running server or you can specify the server name to run against. Additionally you can specify the test suite to run, possible choices include the running application's test suite (app), the core framework test suite (core), or a particular plugin's test suite by passing in the plugin name.

```
wheels test [type] [servername] [reload] [debug]
```

| Parameter  | Required | Default | Description                                    |
| ---------- | -------- | ------- | ---------------------------------------------- |
| type       | false    | app     | Either Core, App, or the name of the plugin    |
| servername | false    |         | Servername to run the tests against            |
| reload     | false    | false   | Force Reload                                   |
| debug      | false    | false   | Output passing tests as well as failing ones   |
| format     | false    | json    | Force a specific return format for debug       |
| adapter    | false    |         | Attempt to override what dbadapter wheels uses |

## `wheels scaffold`

This command will completely scaffold a new object. Typically you would run this command to stub out all the CRUD related files and then follow it up with a series of `wheels g property` commands to add the individual fields to the object. This command will:

* Create a model file
* A Default CRUD Controller complete with create/edit/update/delete code
* View files for all those actions
* Associated test stubs
* DB migration file

This command can be run without the server running except the database migration portion because that requires a running database. So if your server is already up and running you can run this command completely including the database migration portion. Afterwards make sure to run `wheels reload` to reload your application since we just made model changes. If the server isn't running, you can run this command and stub out all the files, then start your server with `server start` and finally migrate the database with `wheels db latest`.

```
wheels scaffold [objectName]
```

| Parameter | Required | Default | Description                        |
| --------- | -------- | ------- | ---------------------------------- |
| Name      | true     |         | Name of the object to scaffold out |

## `wheels destroy`

This command will destroy a given object. This is highly destructive, given the name, so proceed with caution. If you created an object using the `wheels scaffold [objectName]` command, this command is the inverse of that command and will remove all elements created by that command.

This command will destroy the following elements:

* the models definition file
* the controllers definition file
* the view sub folder and all it's contents
* the model test file
* the controller test file
* the views test file
* resource route configuration

```
wheels destroy [objectName]
```

| Parameter | Required | Default | Description                   |
| --------- | -------- | ------- | ----------------------------- |
| Name      | true     |         | Name of the object to destroy |
