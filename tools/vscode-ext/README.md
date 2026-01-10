# Wheels VS Code Extension

The ultimate VS Code extension for Wheels framework development! Boost productivity and makes development easier and faster. Get helpful code completion, file scaffolding, parameter hints, smart navigation, file templates, and real-time validation - all designed for specifically for Wheels developers.

## Features

### File Templates & Scaffolding

Quickly generate controllers, models, and views with ready-made templates that include common code patterns, validations, and best practices.

**How to use it:**
- **Right-click method:** Right-click any folder → "New Wheels Component" → Choose Controller/Model/View → Enter name
- **Command palette:** Ctrl+Shift+P → "Wheels: Model" → Enter name  → Enter target path

**Examples:**

**Creating a Users Controller:**
- Right-click `app/controllers/` folder → "New Wheels Component" → "Controller (CRUD Actions)" → Type "Users"
- Generates `Users.cfc` with complete CRUD actions: index(), show(), new(), create(), edit(), update(), delete()
- Same goes for `models` and `views`

![Wheels File Scaffolding Demo 1](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/demos/scaffolding-demo-1.gif)

**Creating a Product Model:**
- Command Palette → "Wheels: Create Model" → Path: `app/models` → Name: "Product"
- Generates `Product.cfc` with associations, validations, callbacks, and custom finder methods
- Also, you can create `controller` and `view` from this way

![Wheels File Scaffolding Demo 2](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/demos/scaffolding-demo-2.gif)

![Wheels File Scaffolding Demo 3](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/demos/scaffolding-demo-3.gif)

![Wheels File Scaffolding Demo 3](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/demos/scaffolding-demo-4.gif)

**Features:**
- Files use the name you type
- Creates missing directories automatically
- Complete CRUD controllers with error handling
- Models with validations, associations, and custom methods
- Views with proper CFML template structure

---

### Quick Code Templates

#### Component Templates

Create complete component structures instantly with professional templates that include best practices and common patterns.

**How to use it:**
- In any CFML file, type the template keyword (`wcontroller` or `wmodel`)
- Press Tab/Enter to import complete structure
- Language automatically sets to CFML

**Examples:**

**Controller Template:**
```cfml
// Type "wcontroller" + Tab to get:
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

![Wheels Quick Code Demo 1](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/demos/quick-code-demo-1.gif)

**Model Template:**
```cfml
// Type "wmodel" + Tab to get:
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

![Wheels Quick Code Demo 2](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/demos/quick-code-demo-2.gif)

---

#### Function Snippets

Get intelligent code completion for Wheels functions with multiple parameter options - choose between basic **required parameters** or **full parameter** sets.

**How to use it:**
- Type any Wheels function name (e.g., `findAll`, `mimeTypes`)
- Choose from dropdown options:
  - **Basic version** - Only required parameters
  - **Full version** - All available parameters
- Tab through parameters to fill in values

**Examples:**

**Model Functions:**
```cfml
// Type "findAll" and choose from dropdown:
// Option 1: findAll (basic - required params only)
users = findAll()

// Option 2: findAll(allParams) (full version with all parameters)
users = findAll(where = "", order = "", group = "", select = "", distinct = "false", include = "")

// After selecting either option, customize as needed:
users = findAll(where = "active = 1", order = "name ASC")
```

![Wheels Function Snippets Demo 1](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/demos/functions-snippets-demo-1.gif)

**Utility Functions:**
```cfml
// Type "mimeTypes" and choose from dropdown:
// Option 1: mimeTypes (basic - required params only)
type = mimeTypes(extension = "")

// Option 2: mimeTypes(allParams) (with optional fallback)
type = mimeTypes(extension = "", fallback = "")

// Practical usage:
type = mimeTypes(extension = "pdf", fallback = "application/pdf")
```

![Wheels Function Snippets Demo 2](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/demos/functions-snippets-demo-2.gif)

**Features:**
- 300+ Wheels framework functions included
- Dual options: basic (required) vs. full (all parameters)
- Smart parameter completion with Tab navigation
- Context-aware suggestions based on function type

---

### Go to Definition (F12)

Click on Wheels components references to instantly jump to the corresponding file/component. Works with models, controllers, routes, and views.

**How to use it:**
- Ctrl+Click (or Cmd+Click on Mac) on any Wheels component reference
- Or press F12 while cursor is on the component name
- Or right-click → "Go to Definition"

**Examples:**
```cfml
// Ctrl+Click on "User" to jump to `User.cfc` model
user = model("User").findAll();

// Ctrl+Click on "users" to jump to `Users.cfc` controller
redirectTo(controller="users", action="show");

// Ctrl+Click on "editUser" to jump to Users.cfc edit() action
linkTo(route="editUser", key=user.id);

// Ctrl+Click on "users/show" to jump to users/show.cfm
renderView("users/show");
```

![Wheels Go To Definition Demo 1](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/demos/go-to-definition-demo-1.gif)

**Supported patterns:**
- `model("ModelName")` → jumps to `ModelName.cfc`
- `controller="name"` → jumps to `Name.cfc`
- `route="routeName"` → jumps to controller action
- `renderView("path")` → jumps to view file

![Wheels Go To Definition Demo 2](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/demos/go-to-definition-demo-2.gif)

---

### Smart Parameter System

Intelligent parameter assistance for Wheels functions with real-time hints and auto-completion.

---

#### Parameter Highlighting (Ctrl+Shift+Space)

Show function parameters on the fly with smart highlighting that appears when you start typing parameter names.

**How to use it:**
- Type opening parenthesis `(` after any Wheels function call
- Or press Ctrl+Shift+Space to manually trigger
- Start typing parameter names to see intelligent highlighting

**Examples:**
```cfml
// Type opening parenthesis to see all parameters
findAll(     // Shows: where?, order?, group?, select?, include?, cache?, reload?
             // Parameter types: where: string, order: string, group: string, etc.

// Smart highlighting as you type
findAll(w    // Highlights "where" parameter in suggestion list
findAll(wh   // Further narrows to "where"
findAll(where="active = 1", o    // Now highlights "order" parameter
```

![Wheels Parameter Hints Demo](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/demos/parameter-hints-demo.gif)

---

#### Parameter Auto-completion

Type partial parameter names and it will automatically display for quick snippets, press Tab/Enter to auto-complete with parameters.

**How to use it:**
- Type partial parameter name inside function parentheses
- Press Tab/Enter to auto-complete to full `parameterName = ""` format

**Examples:**
```cfml
// Type partial parameter name and press Tab to auto-complete with snippet
findAll(o    // Type "o" + Tab → becomes "order = """
findAll(wh   // Type "wh" + Tab → becomes "where = """
linkTo(rou   // Type "rou" + Tab → becomes "route = """
validatesPresenceOf("name", mes  // Type "mes" + Tab → becomes "message = """

// Works inside function calls with existing parameters
findAll(where="active = 1", o  // Type "o" + Tab → becomes "order = """

// Result after Tab completion:
findAll(where="active = 1", order = "")  // Cursor positioned inside quotes
```

---

#### Parameter Validation

Real-time validation that detects incorrect parameter names in Wheels functions when using named parameter syntax.

**How it works:**
- Only validates when using named parameter syntax with `=` (parameterName="value")
- Validates when user makes a typo of any function parameter
- Yellow underlines show invalid parameter names
- Works with 300+ Wheels framework functions

**Examples:**

**Invalid Parameter Names (Yellow Underlines):**
```cfml
findAll(ordr="name ASC")              // Warning: "Looks invalid parameter 'ordr'. Did you mean 'order'?"
linkTo(rout="users")                  // Warning: "Looks invalid parameter 'rout'. Did you mean 'route'?"
validatesPresenceOf("name", mesage="Required")  // Warning: "Looks invalid parameter 'mesage'. Did you mean 'message'?"
textField(objectNam="user")           // Warning: "Looks invalid parameter 'objectNam'. Did you mean 'objectName'?"
```

**No Warning (Custom Parameters or Too Different):**
```cfml
// Custom parameters - no warnings (respects arguments scope)
findAll(customParam="value")          // No warning (not similar to any parameter)
myFunc(template="email")              // No warning (intentional custom parameter)
process(metadata="data")              // No warning (custom parameter)

// Valid parameters - no warnings
findAll(order="name ASC", where="active = 1")  // No warning (correct)
linkTo(route="users", text="All Users")        // No warning (correct)
```

**Parameter Suggestions:**
When invalid parameters are detected, the extension suggests the correct parameter name:
- `ordr` → suggests `order`
- `wher` → suggests `where`
- `grp` → suggests `group`
- `txt` → suggests `text`
- `mesage` → suggests `message`

![Wheels Parameter Validation Demo](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/demos/parameter-validation-demo.gif)

---

### Hover Documentation

Hover over Wheels function names to see clean, professional documentation with parameter details and examples.

**How to use it:**
- Simply hover your mouse over any Wheels function name
- Documentation appears automatically
- Works across multiple lines

**Examples:**
```cfml
// Hover over "findAll" shows:
// Parameters: where?, order?, group?, select?, include?, cache?, reload?, etc.
// Returns: Query object or array of model instances
// Example: findAll(where="active = 1", order="name ASC")
users = model("User").findAll();

// Hover over "linkTo" shows complete parameter reference:
// route, controller, action, key, params, anchor, text, confirm, method, etc.
// Shows parameter types and default values
linkTo(route="editUser", key=user.id, text="Edit User");

// Hover over "hasMany" shows association options:
// name, class, foreignKey, dependent, include, order, conditions, etc.
hasMany(name="orders", dependent="delete");
```

**Features:**
- Context-aware (shows for function calls, not variables or strings)
- Multi-line function support
- Parameter tables with types, defaults, and descriptions
- Professional VS Code-style formatting
- Fast performance with intelligent caching

![Wheels Hover Documentation Demo](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/demos/hover-docs-demo.gif)

---

## Installation & Setup

1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Search "Wheels"
4. Install and reload VS Code

**No configuration needed** - works immediately with any CFML file.

## Troubleshooting

### Extension Not Working?
- Check file language is set to "CFML" (bottom-right corner of VS Code)
- Reload window: Ctrl+Shift+P → "Developer: Reload Window"

### Go to Definition Not Working?
- Ensure your Wheels project is opened as a workspace folder
- Check file structure follows standard Wheels layout
- Use correct syntax: `model("User")` not `model('User')`

### Parameter Hints Not Showing?
- Use Ctrl+Shift+Space to manually trigger
- Ensure you're in a function call context
- Check file language is set to CFML

### Files Created in Wrong Location?
- Extension creates files where you right-click or specify
- For Command Palette, double-check the target path you entered

## Resources

- [Wheels Documentation](https://wheels.dev/docs)
- [Community Discussions](https://github.com/wheels-dev/wheels/discussions)
- [Report Issues](https://github.com/wheels-dev/wheels/issues)
- [Extension Source Code](https://github.com/wheels-dev/wheels/tree/main/tools/vscode-ext)

---

**Build faster, code smarter — with Wheels!**