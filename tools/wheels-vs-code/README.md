# Wheels VS Code

Code snippets extension for the Wheels.dev framework, providing comprehensive snippets for controllers, models, views, migrations, and more.

## Features

This extension provides 300+ code snippets for Wheels development including:

- **Controller Functions**: Actions, filters, rendering, flash messages, pagination
- **Model Functions**: CRUD operations, associations, validations, callbacks 
- **Migration Functions**: Table creation, column management, indexes, foreign keys
- **View Helpers**: Forms, links, assets, sanitization
- **Configuration**: Settings, routing, environment management
- **Testing**: TestBox integration and test helpers

All snippets include parameter placeholders with tab stops for quick navigation and completion.

## Usage

Simply start typing a Wheels function name in a `.cfm` or `.cfc` file and VS Code will suggest the available snippets. Press `Tab` to accept a suggestion and use `Tab` to navigate between parameters.

Examples:
- Type `findAll` → `findAll(${1:options})`
- Type `hasMany` → `hasMany(${1:name})`  
- Type `renderWith` → `renderWith(${1:data})`

## Requirements

- Visual Studio Code 1.74.0 or higher
- CFML language support extension (recommended)

## Supported CFML Engines

- Adobe ColdFusion 2018+
- Lucee 5.3+
- BoxLang 1.0+

## Installation

1. Open VS Code
2. Go to Extensions (Ctrl/Cmd + Shift + X)
3. Search for "Wheels VS Code"
4. Click Install

## Contributing

This extension is part of the Wheels framework. To contribute:

1. Visit [Wheels on GitHub](https://github.com/cfwheels/cfwheels)
2. Report issues or suggest improvements
3. Submit pull requests for new snippets or fixes

## Release Notes

### 1.0.0

- Initial release with 300+ Wheels code snippets
- Complete coverage of framework API functions
- Parameter placeholders with tab navigation
- Support for all CFML engines

---

## Resources

- [Wheels Documentation](https://wheels.dev)
- [Wheels GitHub](https://github.com/cfwheels/cfwheels)
- [Wheels Community](https://github.com/cfwheels/cfwheels/discussions)

**Happy Coding with Wheels!**
