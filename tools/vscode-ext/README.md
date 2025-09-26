# Wheels VS Code Extension

The ultimate VS Code extension for Wheels framework development! Boost your productivity with intelligent scaffolding, real-time validation, comprehensive snippets, professional documentation, Go to Definition, and IntelliSense parameter hints.

## Features in Action

### File Templates & Scaffolding
![Wheels File Scaffolding](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/wheels-demo-01.gif)

### IntelliSense & Parameter Hints
![Wheels IntelliSense](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/wheels-demo-02.gif)

### Go to Definition & Smart Navigation
![Wheels Navigation](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/wheels-demo-03.gif)

## Key Features

### File Templates & Scaffolding
- **Right-click scaffolding**: Create controllers, models, and views instantly from Explorer
- **Command palette integration**: `Wheels: Create Controller/Model/View`
- **Smart naming conventions**:
  - Input "User" → creates "Users.cfc" controller (plural)
  - Input "User" → creates "User.cfc" model (singular)
  - Automatically handles whitespace trimming
- **Complete templates**: Full CRUD controllers with error handling, models with validations
- **Auto-directory creation**: Creates missing folders automatically
- **Intelligent path detection**: Works from any directory, finds correct app structure

### Go to Definition (F12)
- **Model navigation**: `Cmd+Click` (macOS) or `Ctrl+Click` (Windows/Linux) on `model("User")` → jumps to `User.cfc`
- **Controller actions**: `Cmd+Click` (macOS) or `Ctrl+Click` (Windows/Linux) on `redirectTo(controller="users", action="show")` → jumps to specific action
- **Route-based navigation**: `Cmd+Click` (macOS) or `Ctrl+Click` (Windows/Linux) on `linkTo(route="editUser")` → jumps to controller action
- **View definitions**: `Cmd+Click` (macOS) or `Ctrl+Click` (Windows/Linux) on `renderView("users/show")` → jumps to view file
- **Smart inference**: Handles route patterns like `editUser` → `users#edit`

### IntelliSense Parameter Hints (Ctrl+Shift+Space)
- **Real-time parameter hints**: Shows function signatures as you type
- **Active parameter highlighting**: Highlights current parameter position
- **300+ Wheels functions**: Complete parameter information for all framework functions
- **Method chaining support**: Works with `model("User").findAll()` patterns
- **Smart triggers**: Activates on `(`, `,`, and space characters

### Route Validation
- **Real-time error detection**: Catches route typos as you type
- **Smart suggestions**: `rout=` → suggests `route=`
- **Parameter validation**: Warns about missing `key` parameter in edit/update/delete routes
- **Best practice hints**: Suggests route parameters over controller/action
- **Typo detection**: Identifies suspicious route names and common mistakes

### Enhanced Code Snippets
- **Template snippets**: `wcontroller`, `wmodel` with automatic CFML language detection
- **Rapid development**: Type `wcontroller` + Tab → get complete CRUD controller
- **Best practices included**: Error handling, validation patterns, proper associations
- **Smart caching**: Templates cached for better performance
- **Auto-language detection**: Automatically sets file language to CFML

### Context-Aware Documentation (Hover)
- **Smart hover**: Only shows documentation for actual function calls (not variables or strings)
- **Multi-line support**: Works with function calls spanning multiple lines
- **Professional formatting**: Clean, VS Code-style documentation with examples
- **Parameter tables**: Types, defaults, and descriptions for all parameters
- **Framework context**: Shows which scope functions are available in
- **Performance optimized**: Lazy loading with intelligent caching

### Developer Productivity
- **300+ framework functions** with intelligent autocomplete
- **Two variants per function**: minimal (required) and comprehensive (all params)
- **Multi-version support**: Works with all Wheels versions
- **Zero configuration**: Works out of the box
- **Template caching**: Fast template loading and generation

## Quick Start Guide

### 1. Creating Files

#### Right-Click Method (Recommended)
1. **Right-click any folder** in VS Code Explorer
2. Select **"New Wheels Component"**
3. Choose: **"Controller (CRUD Actions)"**, **"Model (Validations & Associations)"**, or **"View (Template with Layout)"**
4. Enter component name (e.g., "User", "Product")
5. File created with complete template structure

#### Command Palette Method
1. Press `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (Mac)
2. Type: **"Wheels: Create Controller"**
3. Enter component name
4. File created in appropriate directory

### 2. Using Code Snippets

#### Quick Templates
```cfml
// Type "wcontroller" and press Tab:
component extends="Controller" {
    function config() {
        // Filters, verification, formats
        // filters(through="authenticate", except="index");
        // verifies(only="show,edit,update,delete", params="key", paramsTypes="integer");
        // provides("html,json");
    }

    function index() {
        items = model("Item").findAll(order="name ASC");
        // renderWith(items);
    }

    function show() {
        // item is set by findRecord() filter or:
        // item = model("Item").findByKey(params.key);
    }

    // Complete CRUD actions: new, create, edit, update, delete
}
```

```cfml
// Type "wmodel" and press Tab:
component extends="Model" {
    function config() {
        // Associations
        hasMany("orders");
        belongsTo("category");

        // Validations
        validatesPresenceOf("name,email");
        validatesUniquenessOf(property="email");
        validatesFormatOf(property="email", regEx="^[\w\.-]+@[\w\.-]+\.\w+$");

        // Callbacks
        beforeSave("hashPassword");
        afterCreate("sendWelcomeEmail");
    }

    function findByEmail(required string email) {
        return findOne(where="email = '#arguments.email#'");
    }

    function fullName() {
        return trim("#firstname# #lastname#");
    }
}
```

### 3. Navigation with Go to Definition

#### Model Navigation
```cfml
// Ctrl+Click on "User" to jump to User.cfc
user = model("User").findAll();
users = model("User").findByKey(1);
```

#### Controller & Action Navigation
```cfml
// Cmd+Click (macOS) or Ctrl+Click (Windows/Linux) on "users" to jump to Users.cfc
redirectTo(controller="users", action="show", key=user.id);

// Cmd+Click (macOS) or Ctrl+Click (Windows/Linux) on "editUser" to jump to Users.cfc edit() action
linkTo(route="editUser", key=user.id, text="Edit");
```

#### View Navigation
```cfml
// Cmd+Click (macOS) or Ctrl+Click (Windows/Linux) on "users/show" to jump to users/show.cfm
renderView("users/show");
includePartial("shared/header");
```

### 4. IntelliSense Parameter Hints

#### Function Parameter Help
```cfml
// Type opening parenthesis to see parameter hints
findAll(     // Shows: where?, order?, group?, select?, include?, etc.

// Navigate parameters with Tab, see active parameter highlighted
findAll(where="active = 1",     // 'order' parameter now highlighted

// Works with method chaining
model("User").findAll(     // Shows findAll parameters
```

### 5. Hover Documentation

#### Smart Function Help
```cfml
// Hover over any Wheels function for instant documentation
users = findAll()     // Shows: parameters, types, descriptions, examples
linkTo()              // Shows: complete parameter table with defaults
hasMany()             // Shows: association options and usage patterns

// Context-aware: only shows for function calls, not variables
findAll = "some string"  // No hover documentation (correctly detected as variable)
```

### 6. Route Validation in Action

#### Real-time Error Detection
```cfml
// Extension warns about typos:
linkTo(rout="users")              // ERROR: "Did you mean 'route'?"
linkTo(root="home")               // ERROR: "Did you mean 'route'?"

// Warns about missing parameters:
linkTo(route="editUser")          // WARNING: "Edit routes typically require a 'key' parameter"
linkTo(route="deleteUser")        // WARNING: "Delete routes typically require a 'key' parameter"

// Suggests best practices:
linkTo(controller="users", action="index")  // INFO: "Consider using route parameter instead"

// Validates correct usage:
linkTo(route="editUser", key=user.id)      // No warnings
redirectTo(route="users")                   // No warnings
```

#### Suspicious Route Detection
```cfml
// Detects potentially problematic routes:
linkTo(route="a")                 // WARNING: "Potentially invalid route: 'a' (too short)"
linkTo(route="USERS LIST")        // WARNING: "Route contains spaces"
linkTo(route="CONSTANT_NAME")     // WARNING: "All caps route name (might be constant)"
```

## Available Features Reference

### Template Snippets
| Snippet | Description | Auto-Generated Content |
|---------|-------------|------------------------|
| `wcontroller` | Complete CRUD controller | All CRUD actions (index, show, new, create, edit, update, delete) with error handling |
| `wmodel` | Model with validations | Associations, validations, callbacks, custom finder methods |

### Go to Definition Support
| Pattern | Action | Example |
|---------|--------|---------|
| `model("ModelName")` | Jump to model file | `model("User")` → `User.cfc` |
| `controller="name"` | Jump to controller | `redirectTo(controller="users")` → `Users.cfc` |
| `route="routeName"` | Jump to controller action | `linkTo(route="editUser")` → `Users.cfc#edit` |
| `renderView("path")` | Jump to view file | `renderView("users/show")` → `users/show.cfm` |

### IntelliSense Functions
- **300+ Wheels functions** with complete parameter hints
- **Real-time parameter help** with type information
- **Active parameter highlighting** as you type
- **Method chaining support** for complex expressions

### Route Validation Rules
| Validation Type | Detection | Example Warning |
|----------------|-----------|------------------|
| Typos | `rout=`, `root=` | "Did you mean 'route'?" |
| Missing params | Edit/delete routes without `key` | "Typically requires 'key' parameter" |
| Best practices | `controller=` + `action=` usage | "Consider using route parameter" |
| Suspicious routes | Too short, spaces, all caps | "Potentially invalid route" |

### Smart Hover Documentation
- **Context-aware**: Only shows for actual function calls
- **Multi-line support**: Works across line breaks
- **Parameter tables**: Complete parameter reference with types and defaults
- **Framework context**: Shows available scopes (controller, model, view)
- **Professional formatting**: VS Code-style documentation

## Testing All Features

### 1. Testing File Templates

#### Controller Creation
1. Open a Wheels project in VS Code
2. Right-click any folder → "New Wheels Component" → "Controller (CRUD Actions)"
3. Enter "Users" → Should create `Users.cfc` with complete CRUD template
4. Check: Contains index, show, new, create, edit, update, delete actions
5. Verify: File automatically opens and language set to CFML

#### Model Creation
1. Right-click folder → "New Wheels Component" → "Model (Validations & Associations)"
2. Enter "User" → Should create `User.cfc` with validations and associations
3. Check: Contains config() with examples, custom finder methods
4. Verify: Proper singular naming (User.cfc, not Users.cfc)

#### View Creation
1. Right-click folder → "New Wheels Component" → "View (Template with Layout)"
2. Enter "users/index" → Should create `users/index.cfm`
3. Check: Contains proper CFML template structure with contentFor, layout integration

### 2. Testing Go to Definition (F12 or Ctrl+Click)

#### Model Navigation
```cfml
// Test these patterns - should jump to User.cfc:
user = model("User").findAll();
users = model("User").findByKey(1);
```

#### Controller Navigation
```cfml
// Should jump to Users.cfc:
redirectTo(controller="users", action="show");

// Should jump to Users.cfc edit() function:
linkTo(route="editUser", key=1);
```

#### View Navigation
```cfml
// Should jump to users/show.cfm:
renderView("users/show");
includePartial("shared/header");
```

### 3. Testing IntelliSense (Ctrl+Shift+Space)

#### Parameter Hints
1. Type: `findAll(` → Should show parameter popup
2. Type: `where="active = 1",` → Should highlight next parameter
3. Test method chaining: `model("User").findAll(`
4. Verify triggers work: `(`, `,`, space

#### Function Coverage
```cfml
// Test these functions show parameter hints:
findAll(
hasMany(
validatesPresenceOf(
linkTo(
redirectTo(
```

### 4. Testing Route Validation

#### Error Detection
1. Type: `linkTo(rout="test")` → Should show red underline
2. Type: `linkTo(route="editUser")` → Should show yellow warning about missing `key`
3. Type: `linkTo(controller="users", action="index")` → Should show info suggestion
4. Fix to: `linkTo(route="editUser", key=1)` → All warnings should disappear

#### Typo Detection
```cfml
// These should show warnings:
linkTo(rout="users");              // "Did you mean 'route'?"
linkTo(root="home");               // "Did you mean 'route'?"
linkTo(route="a");                 // "Too short, potentially invalid"
linkTo(route="USER LIST");         // "Contains spaces"
```

### 5. Testing Hover Documentation

#### Function Documentation
1. Type: `users = findAll()`
2. Hover over `findAll` → Should show rich documentation with parameters table
3. Type: `linkTo()` → Hover should show complete parameter reference
4. Test multi-line: Hover should work on functions spanning multiple lines

#### Context Awareness
```cfml
// Should show documentation:
users = findAll();           // SHOWS: Hover on findAll
model("User").findAll();     // SHOWS: Hover on findAll

// Should NOT show documentation:
findAll = "some string";     // NO HOVER: Hover on findAll (variable)
"findAll is a function";     // NO HOVER: Hover on findAll (in string)
```

### 6. Testing Code Snippets

#### Template Expansion
1. Create new `.cfc` file (or set language to CFML)
2. Type `wcontroller` + Tab → Should expand to full CRUD controller
3. Type `wmodel` + Tab → Should expand to complete model with validations
4. Verify: Language automatically set to CFML
5. Check: Template caching works (second use should be faster)

#### Auto-Language Detection
1. Create new file (plaintext)
2. Type `wcontroller` + Tab
3. Verify: File language automatically changes to CFML
4. Check: Syntax highlighting active

### 7. Performance Testing

#### Large Files
1. Open large CFML files (1000+ lines)
2. Test hover responsiveness
3. Test Go to Definition speed
4. Verify: No lag or freezing

#### Memory Usage
1. Use multiple features extensively
2. Check VS Code memory usage stays reasonable
3. Verify: Template caching doesn't cause memory leaks

## Building and Installing

### For Development:
```bash
# Install dependencies
cd tools/vscode-ext
npm install

# Package extension
vsce package

# Install locally
code --install-extension wheels-vscode-1.1.0.vsix
```

### For Testing:
1. Open VS Code
2. Go to Extensions view (`Ctrl+Shift+X`)
3. Click "..." → "Install from VSIX..."
4. Select the generated `.vsix` file

## Troubleshooting

### Extension Not Activating?
- **Check language**: Ensure file language is set to "CFML" (bottom-right of VS Code)
- **Reload window**: `Ctrl+Shift+P` → "Developer: Reload Window"
- **Check output**: View → Output → Select "Wheels VS Code" for error messages
- **Verify activation**: Extension should activate automatically when opening CFML files

### Go to Definition Not Working?
- **Workspace folder**: Ensure your Wheels project is opened as a workspace folder
- **File structure**: Extension expects standard Wheels structure (`app/models/`, `app/controllers/`, `app/views/`)
- **File naming**: Controllers should be plural (`Users.cfc`), models singular (`User.cfc`)
- **Syntax**: Use correct syntax: `model("User")`, not `model('User')` or `model(User)`

### IntelliSense Not Showing?
- **Trigger characters**: Make sure you're using `(`, `,`, or space to trigger hints
- **Function context**: IntelliSense only works for recognized Wheels functions
- **File type**: Ensure file is recognized as CFML (check language in status bar)
- **Force trigger**: Use `Ctrl+Shift+Space` to manually trigger parameter hints

### Templates Not Creating Files?
- **Permissions**: Ensure you have write permissions in the target directory
- **Workspace**: Check that workspace folder is properly opened
- **Path issues**: Try using Command Palette instead of right-click menu
- **Directory structure**: Extension will create missing directories automatically
- **Naming**: Avoid special characters, spaces, or invalid file name characters

### Route Validation Too Aggressive?
- **Non-blocking**: Warnings are informational and won't prevent code execution
- **Context-specific**: Validation is designed to catch common Wheels routing mistakes
- **Disable**: Currently no setting to disable, but warnings don't affect functionality
- **False positives**: If you get incorrect warnings, they're safe to ignore

### Hover Documentation Not Appearing?
- **Function calls only**: Documentation only shows for actual function calls, not variables
- **Context detection**: Ensure you're hovering over a function name followed by `(`
- **Multi-line**: Should work across multiple lines, try hovering on function name
- **Performance**: Large files might have slight delay, this is normal

### Performance Issues?
- **Template caching**: Templates are cached after first use for better performance
- **Large projects**: Extension is optimized for large codebases
- **Memory usage**: If VS Code becomes slow, try reloading the window
- **Multiple workspaces**: Having many workspace folders open can impact performance

### Snippets Not Expanding?
- **Language setting**: Ensure file is set to CFML language
- **Trigger**: Type `wcontroller` or `wmodel` exactly, then press Tab
- **File context**: Works in both new files and existing CFML files
- **Auto-detection**: Should automatically set language to CFML after expansion

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "No definition found" | Check file exists in expected location (`app/models/User.cfc`) |
| "Parameter hints not showing" | Use `Ctrl+Shift+Space` or ensure you're in function call context |
| "Route warnings everywhere" | Warnings are informational - your code will still work |
| "Template didn't expand" | Check language is CFML, type exact snippet name + Tab |
| "File created in wrong location" | Extension auto-detects Wheels structure, may create directories |

### Getting Help
- **Extension logs**: Check VS Code Output panel → "Wheels VS Code"
- **VS Code logs**: Help → Toggle Developer Tools → Console
- **GitHub issues**: Report bugs at extension repository
- **Community**: Ask questions in Wheels community discussions

## Resources

- [Wheels Framework Documentation](https://wheels.dev/docs)
- [Community Discussions](https://github.com/wheels-dev/wheels/discussions)
- [Report Issues](https://github.com/wheels-dev/wheels/issues)
- [Extension Source Code](https://github.com/wheels-dev/wheels/tree/main/tools/vscode-ext)

## License

MIT License - free to use, modify, and distribute.

---

**Build faster, code smarter — with Wheels!**