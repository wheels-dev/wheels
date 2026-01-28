# wheels generate snippets

Copies template snippets to your application.

## Synopsis

```bash
wheels generate snippets
wheels g snippets
```

## Description

The `wheels generate snippets` command copies snippet templates to your application's `/app/snippets` folder. This provides you with a collection of code snippet templates that you can use and customize for common Wheels patterns.

## Arguments

None.

## Options

None.

## Usage

### Generate Snippets

```bash
wheels generate snippets
```

Output:
```
Starting snippet generation...
Snippet successfully generated in the /app/snippets folder.
```

This command:
1. Validates that the `app` directory exists in your current location
2. Ensures snippet templates are copied to `/app/snippets`
3. Confirms successful generation

## Requirements

- Must be run from your application root directory (where the `app` folder is located)

## Error Handling

If the command cannot find the `app` directory, it will display an error:
```
[/path/to/app] can't be found. Are you running this command from your application root?
```

## See Also

- [wheels generate controller](controller.md) - Generate controllers
- [wheels generate model](model.md) - Generate models
- [wheels scaffold](scaffold.md) - Generate complete resources