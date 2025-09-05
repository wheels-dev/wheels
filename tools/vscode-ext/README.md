# Wheels VS Code Extension

Boost your Wheels development experience with **intelligent code snippets** for all framework functions, offered in **required-only and full-parameter** variants, along with **integrated function documentation**.

## Features

### Smart Code Completion
**Insert named parameters instantly** - No more positional arguments or parameter guessing

### Professional Hover Docs  
**See examples, parameter details, and defaults** - Just hover over any Wheels function

### Context-Aware Snippets
**Required-only + full options available** - Choose the complexity level you need

### 300+ Functions
**Complete coverage of the Wheels framework** - Every function documented and accessible

### Minimal & Clean Syntax
**No more positional arguments** - Clean, readable named parameter syntax

## Usage

```cfml
// Type "findAll" and choose from dropdown:
// Option 1: findAll (basic - with required params)
users = findAll()

// Option 2: findAll(allParams) (full version with all parameters)
users = findAll(where = "", order = "", group = "", select = "", distinct = "false", include = "")

// Practical usage after selecting either option
users = findAll(where = "active = 1", order = "name ASC")

// Another example - type "mimeTypes":
// Option 1: mimeTypes (basic - with required params)
type = mimeTypes(extension = "")

// Option 2: mimeTypes(allParams) (with fallback)
type = mimeTypes(extension = "", fallback = "")
```

## Quick Start

1. **Open a `.cfm` or `.cfc` file**
2. **Start typing** a Wheels function name (e.g. `findAll`)
3. **Choose between**:
   - Required parameters only
   - Full version with optional params

## Contributing

This extension is part of the [Wheels project](https://wheels.dev).

- [Community Discussions](https://github.com/cfwheels/cfwheels/discussions)
- [Report Issues](https://github.com/cfwheels/cfwheels/issues)
- [Wheels Docs](https://wheels.dev)

## License

**MIT License** — free to use, modify, and distribute.

---

**Build faster, code smarter — with Wheels!**