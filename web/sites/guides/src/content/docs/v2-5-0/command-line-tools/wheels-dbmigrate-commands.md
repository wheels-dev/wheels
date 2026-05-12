---
title: wheels dbmigrate - commands
---
# wheels dbmigrate - commands

These are the commands in the `wheels dbmigrate` namespace. They allow you to manipulate the
database structure and script the changes. This makes is easy to share your changes with
coworkers, check them into source control, or apply them automatically when you deploy your
code to production.

## `wheels dbmigrate`

This is another namespace with sub commands within it. It also has an alias of `wheels db` which allows you to shorten the command you need to type.

## `wheels dbmigrate info`

This command doesn't take any inputs but simply tries to communicate with the running server and gather information
about your migrations and displays them in a table.

```
wheels dbmigrate info
```

```
❯ wheels db info
Sending: http://127.0.0.1:59144/rewrite.cfm?controller=wheels&action=wheels&view=cli&command=info
Call to bridge was successful.
+-----------------------------------------+-----------------------------------------+
| Datasource:               MyCFWheelsApp | Total Migrations:                     3 |
| Database Type:                       H2 | Available Migrations:                 2 |
|                                         | Current Version:         20220619110404 |
|                                         | Latest Version:          20220619110706 |
+-----------------------------------------+-----------------------------------------+
+----------+------------------------------------------------------------------------+
|          | 20220619110706_cli_create_column_user_lastname                         |
|          | 20220619110540_cli_create_column_user_firstname                        |
| migrated | 20220619110404_cli_create_table_users                                  |
+----------+------------------------------------------------------------------------+
```

From the information presented in the two tables you can see how many migration files are in your
application and of those how many have already been applied and available to be applied. You are
also presented with the datasource name and database type information.

## `wheels dbmigrate latest`

This command will migrate the database to the latest version. This command will apply each migration
file from the current state all the way to the latest one at a time. If a SQL error is encountered
in one of the files, the command will stop at that point and report the error.

```
wheels dbmigrate latest
```

## `wheels dbmigrate reset`

This command will migrate the database to version 0 effectively resetting the database to nothing.

```
wheels dbmigrate reset
```

## `wheels dbmigrate up`

This command will process the next migration file from the current state. If the database is already at
the latest version this command will have no effect.

```
wheels dbmigrate up
```

## `wheels dbmigrate down`

This command will reverse the current migration file and take the database one step backwards. If the database is
already at version 0 then this command will have no effect.

```
wheels dbmigrate down
```

## `wheels dbmigrate exec`

This command will run a particular migration file and take the database to that version. The four directional
migration commands above `latest`, `reset`, `up`, and `down` each in turn call this command to process their
intended action.

```
wheels dbmigrate exec [version]
```

| Parameter  | Required | Default | Description                                         |
| ---------- | -------- | ------- | --------------------------------------------------- |
| version    | true     |         | The version to migrate the database to              |

## `wheels dbmigrate create table`

This command will generate a new migration file for creating a table in the database. Keep in mind you will
still have to run the migration file but this will add it to the migration history.

```
wheels dbmigrate create table [name] [force] [id] [primaryKey]
```

| Parameter  | Required | Default | Description                                         |
| ---------- | -------- | ------- | --------------------------------------------------- |
| name       | true     |         | The name of the database table to create            |
| force      | false    | false   | Force the creation of the table                     |
| id         | false    | true    | Auto create ID column as autoincrement ID           |
| primaryKey | false    | ID      | Overrides the default primary key column name       |

## `wheels dbmigrate create column`

This command will generate a new migration file for adding a new column to an existing table.

```
wheels dbmigrate create column [name] [columnType] [columnName] [default] [null] [limit] [precision] [scale]
```

| Parameter  | Required | Default | Description                                         |
| ---------- | -------- | ------- | --------------------------------------------------- |
| name       | true     |         | The name of the database table to modify            |
| columnType | true     |         | The column type to add                              |
| columnName | false    |         | The column name to add                              |
| default    | false    |         | The default value to set for the column             |
| null       | false    | true    | Should the column allow nulls                       |
| limit      | false    |         | The character limit of the column                   |
| precision  | false    |         | The precision of the numeric column                 |
| scale      | false    |         | The scale of the numeric column                     |

## `wheels dbmigrate create blank`

## `wheels dbmigrate remove table`

This command generates a migration file to remove a table. The migration file is will still need to be run
individual but this command gets the migration generated and into the history.

```
wheels dbmigrate remove table [name]
```

| Parameter  | Required | Default | Description                                         |
| ---------- | -------- | ------- | --------------------------------------------------- |
| name       | true     |         | The name of the database table to remove            |
